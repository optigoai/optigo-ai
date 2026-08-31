// ==================================================
// OptigoAI Enterprise — Prody Light Content Studio
// ==================================================

import React, { useState } from 'react';
import { useLocation } from '../../context/LocationContext';
import {
  FileText,
  Copy,
  Check,
  Plus,
} from 'lucide-react';

export const BranchContentView: React.FC = () => {
  const { activeLocation } = useLocation();
  const [topic, setTopic] = useState('Weekend Special Menu');
  const [channel, setChannel] = useState('Google Business Update');
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);

  const [posts, setPosts] = useState([
    {
      id: 'p-1',
      title: 'Weekend Dining Special',
      body: `Visit ${activeLocation?.name || 'our restaurant'} this weekend for handcrafted culinary specials and refreshing beverages. Check directions directly via Google Maps!`,
      tags: '#LocalDining #WeekendSpecial #OptigoAI',
      channel: 'Google Business Update',
      scheduled_for: 'Saturday, 12:00 PM',
      status: 'Ready',
    },
    {
      id: 'p-2',
      title: 'Private Suites & Events',
      body: `Host your family celebrations and corporate dinners at ${activeLocation?.name || 'our venue'}. Direct inquiries and bookings available via Google Maps.`,
      tags: '#DiningEvents #CorporateDinners #PrivateSuites',
      channel: 'Google Business Update',
      scheduled_for: 'Next Tuesday, 10:00 AM',
      status: 'Scheduled',
    },
  ]);

  if (!activeLocation) return null;

  const handleGenerateNew = (e: React.FormEvent) => {
    e.preventDefault();
    if (!topic.trim()) return;

    setPosts((prev) => [
      {
        id: `p-${Date.now()}`,
        title: topic,
        body: `Discover seasonal specials at ${activeLocation.name}! Handcrafted with quality ingredients. Visit us or call directly from Google Maps.`,
        tags: `#${activeLocation.category?.replace(/\s+/g, '') || 'Local'} #BusinessUpdate`,
        channel,
        scheduled_for: 'Tomorrow, 5:00 PM',
        status: 'Ready',
      },
      ...prev,
    ]);
  };

  const handleCopy = (text: string, idx: number) => {
    navigator.clipboard.writeText(text);
    setCopiedIndex(idx);
    setTimeout(() => setCopiedIndex(null), 2000);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <FileText size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Marketing Studio & Posts
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">Google Business Profile Posts</span>
              <span className="prody-pill green">Promotional Broadcasts</span>
            </div>
          </div>
        </div>
      </div>

      {/* 2. Draft Box */}
      <div className="prody-card">
        <form onSubmit={handleGenerateNew} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <h3 style={{ fontSize: '0.96rem', fontWeight: 700, color: '#111827' }}>Draft Promotional Update</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '12px' }}>
            <input
              type="text"
              className="optigo-input"
              placeholder="What promotion would you like to post?"
              value={topic}
              onChange={(e) => setTopic(e.target.value)}
              required
            />
            <select className="optigo-input" value={channel} onChange={(e) => setChannel(e.target.value)}>
              <option value="Google Business Update">Google Business Update</option>
              <option value="Social Announcement">Social Announcement</option>
            </select>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button type="submit" className="btn btn-coral btn-sm" style={{ gap: '4px' }}>
              <Plus size={14} />
              <span>Draft Post</span>
            </button>
          </div>
        </form>
      </div>

      {/* 3. Feed */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '16px' }}>
        {posts.map((post, idx) => (
          <div key={post.id} className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '12px' }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span className="prody-pill blue">{post.channel}</span>
                <span className="prody-pill green">{post.status}</span>
              </div>
              <h3 style={{ fontSize: '1rem', fontWeight: 700, color: '#111827', marginBottom: '6px' }}>{post.title}</h3>
              <p style={{ fontSize: '0.84rem', color: '#4B5563', lineHeight: 1.4, marginBottom: '8px' }}>"{post.body}"</p>
              <span style={{ fontSize: '0.75rem', color: '#0284C7', fontWeight: 600 }}>{post.tags}</span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-subtle)', paddingTop: '10px' }}>
              <span style={{ fontSize: '0.75rem', color: '#9CA3AF' }}>{post.scheduled_for}</span>
              <button onClick={() => handleCopy(`${post.body}\n\n${post.tags}`, idx)} className="btn btn-secondary btn-sm" style={{ gap: '4px' }}>
                {copiedIndex === idx ? <Check size={13} color="#059669" /> : <Copy size={13} />}
                <span>{copiedIndex === idx ? 'Copied' : 'Copy'}</span>
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
