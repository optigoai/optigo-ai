import time
import json
from typing import Dict, Any, List, Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging import get_logger
from app.models.ai_log import AIRequestLog
from app.providers.base import AIProvider
from app.ai.gemini_provider import GeminiAIProvider
from app.ai.schemas import (
    AIBusinessProfileOutput,
    AIBusinessIntelligenceOutput,
    AICMORecommendationsOutput,
)
from app.ai.prompts.business_prompts import (
    BUSINESS_PROFILE_SYSTEM_PROMPT,
    BUSINESS_INTELLIGENCE_SYSTEM_PROMPT,
    CMO_RECOMMENDATIONS_SYSTEM_PROMPT,
    build_business_profile_prompt,
    build_business_intelligence_prompt,
    build_cmo_recommendations_prompt,
)

logger = get_logger("app.ai.service")

# Approximate Gemini 2.0 Flash Pricing per 1M tokens ($0.10 input, $0.40 output)
COST_PER_1M_INPUT = 0.10
COST_PER_1M_OUTPUT = 0.40


class AIService:
    def __init__(self, db: AsyncSession, provider: Optional[AIProvider] = None):
        self.db = db
        self.provider = provider or GeminiAIProvider()

    async def _log_ai_request(
        self,
        feature: str,
        organization_id: Optional[str],
        user_id: Optional[str],
        model: str,
        prompt_preview: str,
        response_preview: str,
        usage: Dict[str, Any],
        is_success: bool,
        error_message: Optional[str] = None,
    ) -> None:
        input_tokens = usage.get("input_tokens", 0)
        output_tokens = usage.get("output_tokens", 0)
        total_tokens = input_tokens + output_tokens
        latency_ms = usage.get("latency_ms", 0)

        # Calculate estimated cost in USD
        cost = (input_tokens / 1_000_000 * COST_PER_1M_INPUT) + (
            output_tokens / 1_000_000 * COST_PER_1M_OUTPUT
        )

        log = AIRequestLog(
            organization_id=organization_id,
            user_id=user_id,
            feature=feature,
            provider="gemini",
            model=model,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            latency_ms=latency_ms,
            estimated_cost_usd=round(cost, 6),
            success=is_success,
            error_message=error_message,
            request_metadata={
                "prompt_preview": prompt_preview[:300] if prompt_preview else None,
                "response_preview": response_preview[:300] if response_preview else None,
            },
        )
        self.db.add(log)
        await self.db.flush()

    async def generate_business_profile(
        self,
        organization_id: Optional[str],
        user_id: Optional[str],
        name: str,
        category: str,
        location: str,
        website: str,
        target_customers: str,
        services: str,
        business_goals: str,
        marketing_channels: str,
    ) -> AIBusinessProfileOutput:
        prompt = build_business_profile_prompt(
            name=name,
            category=category,
            location=location,
            website=website,
            target_customers=target_customers,
            services=services,
            business_goals=business_goals,
            marketing_channels=marketing_channels,
        )

        try:
            res = await self.provider.generate_structured(
                prompt=prompt,
                response_schema=AIBusinessProfileOutput.model_json_schema(),
                system_instruction=BUSINESS_PROFILE_SYSTEM_PROMPT,
                temperature=0.3,
            )
            data = res.get("data", {})
            output = AIBusinessProfileOutput.model_validate(data)

            await self._log_ai_request(
                feature="business_profile_generation",
                organization_id=organization_id,
                user_id=user_id,
                model=res.get("model", "gemini-2.0-flash"),
                prompt_preview=prompt,
                response_preview=str(data),
                usage=res.get("usage", {}),
                is_success=True,
            )
            return output
        except Exception as e:
            logger.error("AI Business Profile generation failed", error=str(e))
            await self._log_ai_request(
                feature="business_profile_generation",
                organization_id=organization_id,
                user_id=user_id,
                model="gemini-2.0-flash",
                prompt_preview=prompt,
                response_preview="",
                usage={"latency_ms": 0},
                is_success=False,
                error_message=str(e),
            )
            raise e

    async def generate_cmo_recommendations(
        self,
        organization_id: Optional[str],
        user_id: Optional[str],
        business_name: str,
        category: str,
        location: str,
        health_score: int,
        problems: list[dict[str, Any]],
        opportunities: list[dict[str, Any]],
        reviews_count: int,
        unanswered_count: int,
    ) -> AICMORecommendationsOutput:
        prompt = build_cmo_recommendations_prompt(
            business_name=business_name,
            category=category,
            location=location,
            health_score=health_score,
            problems=problems,
            opportunities=opportunities,
            reviews_count=reviews_count,
            unanswered_count=unanswered_count,
        )

        try:
            res = await self.provider.generate_structured(
                prompt=prompt,
                response_schema=AICMORecommendationsOutput.model_json_schema(),
                system_instruction=CMO_RECOMMENDATIONS_SYSTEM_PROMPT,
                temperature=0.3,
            )
            data = res.get("data", {})
            output = AICMORecommendationsOutput.model_validate(data)
            usage = res.get("usage", {})

            await self._log_ai_request(
                feature="cmo_recommendations_generation",
                organization_id=organization_id,
                user_id=user_id,
                model=res.get("model", getattr(self.provider, "model_name", "gemini-2.0-flash")),
                prompt_preview=prompt,
                response_preview=json.dumps(data),
                usage=usage,
                is_success=True,
            )
            return output
        except Exception as e:
            logger.error("AI CMO Recommendations generation failed", error=str(e))
            await self._log_ai_request(
                feature="cmo_recommendations_generation",
                organization_id=organization_id,
                user_id=user_id,
                model=getattr(self.provider, "model_name", "gemini-2.0-flash"),
                prompt_preview=prompt,
                response_preview="",
                usage={"latency_ms": 0},
                is_success=False,
                error_message=str(e),
            )
            raise e

    async def generate_business_intelligence(
        self,
        organization_id: Optional[str],
        user_id: Optional[str],
        business_name: str,
        category: str,
        location: str,
        goals: str,
        reviews: List[Dict[str, Any]],
        metrics: Dict[str, Any],
    ) -> AIBusinessIntelligenceOutput:
        prompt = build_business_intelligence_prompt(
            business_name=business_name,
            category=category,
            location=location,
            goals=goals,
            reviews=reviews,
            metrics=metrics,
        )

        try:
            res = await self.provider.generate_structured(
                prompt=prompt,
                response_schema=AIBusinessIntelligenceOutput.model_json_schema(),
                system_instruction=BUSINESS_INTELLIGENCE_SYSTEM_PROMPT,
                temperature=0.2,
            )
            data = res.get("data", {})
            output = AIBusinessIntelligenceOutput.model_validate(data)

            await self._log_ai_request(
                feature="business_intelligence_health_scoring",
                organization_id=organization_id,
                user_id=user_id,
                model=res.get("model", "gemini-2.0-flash"),
                prompt_preview=prompt,
                response_preview=str(data),
                usage=res.get("usage", {}),
                is_success=True,
            )
            return output
        except Exception as e:
            logger.error("AI Business Intelligence generation failed", error=str(e))
            await self._log_ai_request(
                feature="business_intelligence_health_scoring",
                organization_id=organization_id,
                user_id=user_id,
                model="gemini-2.0-flash",
                prompt_preview=prompt,
                response_preview="",
                usage={"latency_ms": 0},
                is_success=False,
                error_message=str(e),
            )
            raise e
