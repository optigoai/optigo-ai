# ==================================================
# OptigoAI Backend — Razorpay Payments Webhook & API
# ==================================================

import hmac
import hashlib
import json
from datetime import datetime
from typing import Dict, Any
from fastapi import APIRouter, Request, HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.logging import get_logger
from app.api.v1.deps import get_db
from app.services.lead_service import LeadService
from app.schemas.lead import LeadVerifyPaymentRequest

logger = get_logger("app.api.v1.payments")

router = APIRouter(prefix="/payments", tags=["Payments & Checkout"])


@router.post("/webhook", summary="Razorpay Webhook Listener")
async def razorpay_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """
    Razorpay Webhook endpoint.
    Acts as a secure, server-side safety net to capture payments
    and convert leads even if user closes the tab before checkout redirects.
    """
    raw_body = await request.body()
    signature = request.headers.get("x-razorpay-signature")

    webhook_secret = settings.razorpay_webhook_secret or settings.razorpay_key_secret

    # Verify webhook signature if secret configured
    if webhook_secret and signature:
        expected_sig = hmac.new(
            webhook_secret.encode("utf-8"),
            raw_body,
            hashlib.sha256,
        ).hexdigest()

        if not hmac.compare_digest(expected_sig, signature):
            logger.error("Razorpay webhook signature verification failed!")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid webhook signature",
            )

    try:
        event_data = json.loads(raw_body.decode("utf-8"))
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid JSON payload",
        )

    event_type = event_data.get("event")
    logger.info(f"Received Razorpay webhook event: {event_type}")

    # Handle payment.captured or order.paid
    if event_type in ("payment.captured", "order.paid"):
        payment_entity = event_data.get("payload", {}).get("payment", {}).get("entity", {})
        notes = payment_entity.get("notes", {})
        lead_id = notes.get("lead_id")
        payment_id = payment_entity.get("id")
        order_id = payment_entity.get("order_id")

        if not lead_id and order_id:
            # Look up lead by order_id
            service = LeadService(db)
            lead = await service.repo.get_by_payment_id(order_id)
            if lead:
                lead_id = str(lead.id)

        if lead_id:
            service = LeadService(db)
            lead = await service.repo.get_by_id(lead_id)
            if lead and lead.payment_status != "paid":
                verify_req = LeadVerifyPaymentRequest(
                    razorpay_order_id=order_id,
                    razorpay_payment_id=payment_id,
                    razorpay_signature="webhook_verified",
                    user_email=payment_entity.get("email") or lead.email,
                )
                try:
                    await service.verify_payment_and_convert(lead_id, verify_req)
                    logger.info(f"Lead {lead_id} successfully converted via webhook for payment {payment_id}")
                except Exception as err:
                    logger.error(f"Failed to convert lead {lead_id} via webhook: {err}")

    return {"status": "ok"}
