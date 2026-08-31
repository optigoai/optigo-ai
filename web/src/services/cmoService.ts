// ==================================================
// OptigoAI Enterprise — Real AI CMO Chat Service
// ==================================================

import { apiRequest } from './api';

export interface ChatMessage {
  id: string;
  sender: 'user' | 'cmo';
  text: string;
  timestamp: string;
  recommended_actions?: string[];
}

export const cmoService = {
  async sendMessage(
    businessId: string,
    message: string,
    contextScreen: string = 'EnterpriseDashboard'
  ): Promise<ChatMessage> {
    const res = await apiRequest<{ response: string; recommendations?: string[] }>('/cmo/chat', {
      method: 'POST',
      body: JSON.stringify({
        business_id: businessId,
        message,
        context_screen: contextScreen,
      }),
    });

    return {
      id: `cmo-${Date.now()}`,
      sender: 'cmo',
      text: res.response,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      recommended_actions: res.recommendations || [],
    };
  },
};
