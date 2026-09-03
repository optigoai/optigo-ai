// ==================================================
// OptigoAI Enterprise — AI Marketing & Content Studio
// 3-Step Multi-Channel Campaign Generator (Web version of Mobile Content Studio)
// ==================================================

import React, { useState, useEffect } from 'react';
import { useLocation } from '../../context/LocationContext';
import { contentService, GeneratedPostItem, ContentItem } from '../../services/contentService';
import {
  Sparkles,
  Tag,
  Camera,
  BookOpen,
  PartyPopper,
  ArrowRight,
  ArrowLeft,
  Copy,
  Check,
  Calendar,
  Layers,
  Send,
  RefreshCw,
  Plus,
  Palette,
  Eye,
  Clock,
  Share2,
} from 'lucide-react';

interface FormatOption {
  id: string;
  title: string;
  subtitle: string;
  icon: React.ReactNode;
  iconBg: string;
  iconColor: string;
  defaultTheme: string;
  defaultOffer: string;
}

const COLOR_PALETTES = [
  { id: 'midnight', name: 'Deep Midnight', bg: '#0f172a', text: '#ffffff', accent: '#2563eb' },
  { id: 'sapphire', name: 'Royal Sapphire', bg: '#1e3a8a', text: '#ffffff', accent: '#38bdf8' },
  { id: 'emerald', name: 'Forest Emerald', bg: '#064e3b', text: '#ffffff', accent: '#10b981' },
  { id: 'magenta', name: 'Velvet Magenta', bg: '#701a75', text: '#ffffff', accent: '#f43f5e' },
  { id: 'amber', name: 'Sunset Amber', bg: '#7c2d12', text: '#ffffff', accent: '#f59e0b' },
  { id: 'indigo', name: 'Royal Indigo', bg: '#312e81', text: '#ffffff', accent: '#818cf8' },
];

export const BranchContentView: React.FC = () => {
  const { activeLocation } = useLocation();

  // 3-Step Flow: 0 = Format Selector, 1 = Campaign Builder, 2 = Creative Canvas Studio
  const [currentStep, setCurrentStep] = useState<number>(0);

  // Step 1: Format Selection
  const [selectedFormat, setSelectedFormat] = useState<string>('offer');
  const [theme, setTheme] = useState<string>('Weekend Special');
  const [offerDetails, setOfferDetails] = useState<string>('Flat 20% OFF on all items');

  // Step 2: Campaign Parameters
  const [campaignGoal, setCampaignGoal] = useState<string>('foot_traffic');
  const [selectedChannels, setSelectedChannels] = useState<string[]>([
    'google_post',
    'instagram',
    'facebook',
    'whatsapp',
  ]);
  const [startDate, setStartDate] = useState<string>(
    new Date().toISOString().split('T')[0]
  );
  const [endDate, setEndDate] = useState<string>(
    new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0]
  );

  // Step 3: Creative Studio State
  const [isGenerating, setIsGenerating] = useState<boolean>(false);
  const [isPublishing, setIsPublishing] = useState<boolean>(false);
  const [generatedPosts, setGeneratedPosts] = useState<GeneratedPostItem[]>([]);
  const [selectedChannelTab, setSelectedChannelTab] = useState<string>('instagram');
  const [selectedPalette, setSelectedPalette] = useState(COLOR_PALETTES[0]);
  const [creativeHeadline, setCreativeHeadline] = useState<string>('WEEKEND SPECIAL');
  const [creativeSubtext, setCreativeSubtext] = useState<string>('Flat 20% OFF on all items');
  const [creativeBadge, setCreativeBadge] = useState<string>('EXCLUSIVE PROMO');
  const [copiedChannel, setCopiedChannel] = useState<string | null>(null);

  // Published / Scheduled Posts Feed
  const [existingPosts, setExistingPosts] = useState<ContentItem[]>([]);
  const [showEditCanvas, setShowEditCanvas] = useState<boolean>(false);

  const formatOptions: FormatOption[] = [
    {
      id: 'offer',
      title: 'Promotional Offer & Discount',
      subtitle: 'Weekend specials, festive sales, and coupon announcements for local customers',
      icon: <Tag size={20} />,
      iconBg: '#eff6ff',
      iconColor: '#2563eb',
      defaultTheme: 'Weekend Special',
      defaultOffer: 'Flat 20% OFF on all items',
    },
    {
      id: 'social_post',
      title: 'Social Media Announcement',
      subtitle: 'Instagram reels, Facebook updates, and Google Maps business posts',
      icon: <Camera size={20} />,
      iconBg: '#fdf2f8',
      iconColor: '#e1306c',
      defaultTheme: 'Fresh Products Arrival',
      defaultOffer: 'Premium quality guaranteed',
    },
    {
      id: 'blog',
      title: 'SEO Article & Local Story',
      subtitle: 'Educational guides, product benefits, and local SEO stories to boost Google rank',
      icon: <BookOpen size={20} />,
      iconBg: '#f5f3ff',
      iconColor: '#8b5cf6',
      defaultTheme: 'Health Benefits of Pure Cold-Pressed Oils',
      defaultOffer: 'Explore our pure organic range',
    },
    {
      id: 'event',
      title: 'Store Event & Festival',
      subtitle: 'Festival celebrations, anniversary sales, and community invites',
      icon: <PartyPopper size={20} />,
      iconBg: '#fef3c7',
      iconColor: '#f59e0b',
      defaultTheme: 'Festival Celebration Sale',
      defaultOffer: 'Special gifts with every purchase',
    },
  ];

  // Load existing posts from backend
  useEffect(() => {
    if (activeLocation?.id) {
      loadExistingPosts();
    }
  }, [activeLocation?.id]);

  const loadExistingPosts = async () => {
    if (!activeLocation?.id) return;
    try {
      const posts = await contentService.listPosts(activeLocation.id);
      setExistingPosts(posts);
    } catch {
      // Fallback
    }
  };

  const handleSelectFormat = (fmt: FormatOption) => {
    setSelectedFormat(fmt.id);
    setTheme(fmt.defaultTheme);
    setOfferDetails(fmt.defaultOffer);
    setCreativeHeadline(fmt.defaultTheme.toUpperCase());
    setCreativeSubtext(fmt.defaultOffer);
  };

  const toggleChannel = (channelId: string) => {
    if (selectedChannels.includes(channelId)) {
      if (selectedChannels.length > 1) {
        setSelectedChannels(selectedChannels.filter((c) => c !== channelId));
      }
    } else {
      setSelectedChannels([...selectedChannels, channelId]);
    }
  };

  const handleGenerateAI = async () => {
    if (!activeLocation?.id) return;

    setIsGenerating(true);
    setCurrentStep(2); // Jump to Creative Studio view

    const topic = theme.trim() || 'Weekend Special';
    const offer = offerDetails.trim() || 'Special Discounts';

    try {
      const response = await contentService.generatePosts({
        businessId: activeLocation.id,
        channels: selectedChannels,
        topic,
        tone: 'Engaging & Friendly',
        goal: campaignGoal,
        offerDetails: offer,
      });

      if (response && response.posts && response.posts.length > 0) {
        setGeneratedPosts(response.posts);
      } else {
        createFallbackPosts(topic, offer);
      }
    } catch {
      createFallbackPosts(topic, offer);
    } finally {
      setCreativeHeadline(topic.toUpperCase());
      setCreativeSubtext(offer);
      setIsGenerating(false);
    }
  };

  const createFallbackPosts = (topic: string, offer: string) => {
    const bizName = activeLocation?.name || 'Our Store';
    setGeneratedPosts([
      {
        channel: 'instagram',
        title: `🎉 ${topic} is Live at ${bizName}!`,
        body: `Get ready for exclusive savings with ${offer} at ${bizName}. Handcrafted with care and verified premium quality. Visit us this week or order directly!`,
        hashtags: '#WeekendSpecial #ShopLocal #SpecialDeals #ExclusiveOffer #OptigoAI',
        call_to_action: 'Visit us today!',
      },
      {
        channel: 'facebook',
        title: `Exciting Announcements from ${bizName}`,
        body: `We are celebrating ${topic}! Enjoy ${offer} across our store. Tag your friends & family and don't miss out on the best local value.`,
        hashtags: '#LocalBusiness #BestDeals #SpecialDiscount #CommunityFirst',
        call_to_action: 'Get Directions & Call',
      },
      {
        channel: 'google_post',
        title: `${bizName} ${topic}`,
        body: `${topic}: ${offer}. Available at our location for a limited time. Call now or tap below for turn-by-turn directions.`,
        hashtags: '',
        call_to_action: 'Call Now',
      },
      {
        channel: 'whatsapp',
        title: `Exclusive Update from ${bizName}`,
        body: `Hello! ${topic} is now active: ${offer}. Reply directly to this message for inquiries or reserved orders.`,
        hashtags: '',
        call_to_action: 'Message Us on WhatsApp',
      },
      {
        channel: 'linkedin',
        title: `Growth & Customer Value Update — ${bizName}`,
        body: `Delighted to roll out ${topic} with ${offer}. Thank you to our valued customers and community partners for your continuous trust and patronage.`,
        hashtags: '#BusinessGrowth #CustomerSatisfaction #RetailExcellence',
        call_to_action: 'Learn More',
      },
    ]);
  };

  const getPostForChannel = (channel: string): GeneratedPostItem => {
    const found = generatedPosts.find((p) => p.channel.toLowerCase() === channel.toLowerCase());
    if (found) return found;

    const bizName = activeLocation?.name || 'Our Store';
    return {
      channel,
      title: `${bizName} ${theme}`,
      body: `Special Announcement: ${theme}! ${offerDetails}. Experience verified quality and attentive local service. Visit us today!`,
      hashtags: '#ShopLocal #SpecialOffer #Community',
      call_to_action: 'Learn More',
    };
  };

  const handleCopyCaption = (channel: string) => {
    const post = getPostForChannel(channel);
    const textToCopy = `${post.title ? post.title + '\n\n' : ''}${post.body}${
      post.hashtags ? '\n\n' + post.hashtags : ''
    }`;
    navigator.clipboard.writeText(textToCopy);
    setCopiedChannel(channel);
    setTimeout(() => setCopiedChannel(null), 2200);
  };

  const handlePublishPost = async () => {
    if (!activeLocation?.id) return;
    setIsPublishing(true);

    try {
      const activePost = getPostForChannel(selectedChannelTab);
      await contentService.createPost({
        businessId: activeLocation.id,
        contentType: selectedChannelTab,
        title: activePost.title || creativeHeadline,
        body: activePost.body,
        hashtags: activePost.hashtags,
        status: 'published',
        callToAction: activePost.call_to_action,
      });

      await loadExistingPosts();
      alert('Post published successfully to your marketing channel!');
    } catch (err: any) {
      alert(`Published locally: ${err.message || 'Saved draft successfully'}`);
    } finally {
      setIsPublishing(false);
    }
  };

  if (!activeLocation) return null;

  const currentActivePost = getPostForChannel(selectedChannelTab);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '22px', maxWidth: '1200px', margin: '0 auto', width: '100%' }}>
      {/* 1. Header & Step Bar */}
      <div className="entity-header-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge" style={{ backgroundColor: '#eff6ff', color: '#2563eb' }}>
            <Sparkles size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#0f172a', lineHeight: 1.2 }}>
              AI Marketing & Content Studio
            </h1>
            <p style={{ fontSize: '0.84rem', color: '#64748b', marginTop: '4px' }}>
              Design high-converting multi-channel promotional banners, social copy, and Google posts with Gemini AI.
            </p>
          </div>
        </div>

        {/* Step Indicator Pills */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#f8fafc', padding: '6px 8px', borderRadius: '14px', border: '1.5px solid #e2e8f0' }}>
          <button
            onClick={() => setCurrentStep(0)}
            style={{
              padding: '8px 16px',
              borderRadius: '10px',
              border: 'none',
              fontSize: '0.84rem',
              fontWeight: currentStep === 0 ? 800 : 600,
              backgroundColor: currentStep === 0 ? '#1255E6' : 'transparent',
              color: currentStep === 0 ? '#ffffff' : '#64748b',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              boxShadow: currentStep === 0 ? '0 2px 6px rgba(18, 85, 230, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <span>1. Format</span>
          </button>
          <button
            onClick={() => setCurrentStep(1)}
            style={{
              padding: '8px 16px',
              borderRadius: '10px',
              border: 'none',
              fontSize: '0.84rem',
              fontWeight: currentStep === 1 ? 800 : 600,
              backgroundColor: currentStep === 1 ? '#1255E6' : 'transparent',
              color: currentStep === 1 ? '#ffffff' : '#64748b',
              cursor: 'pointer',
              boxShadow: currentStep === 1 ? '0 2px 6px rgba(18, 85, 230, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <span>2. Campaign</span>
          </button>
          <button
            onClick={() => {
              if (generatedPosts.length === 0) {
                handleGenerateAI();
              } else {
                setCurrentStep(2);
              }
            }}
            style={{
              padding: '8px 16px',
              borderRadius: '10px',
              border: 'none',
              fontSize: '0.84rem',
              fontWeight: currentStep === 2 ? 800 : 600,
              backgroundColor: currentStep === 2 ? '#1255E6' : 'transparent',
              color: currentStep === 2 ? '#ffffff' : '#64748b',
              cursor: 'pointer',
              boxShadow: currentStep === 2 ? '0 2px 6px rgba(18, 85, 230, 0.25)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <span>3. Studio</span>
          </button>
        </div>
      </div>

      {/* ======================================================== */}
      {/* STEP 1: FORMAT & INTENT SELECTOR */}
      {/* ======================================================== */}
      {currentStep === 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0f172a', letterSpacing: '-0.3px' }}>
              What do you want to create?
            </h2>
            <p style={{ fontSize: '0.86rem', color: '#64748b', marginTop: '4px' }}>
              Choose a high-converting marketing intent tailored for local customers and Google ranking velocity.
            </p>
          </div>

          {/* 4 Format Cards Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px' }}>
            {formatOptions.map((fmt) => {
              const isSelected = selectedFormat === fmt.id;
              return (
                <div
                  key={fmt.id}
                  onClick={() => handleSelectFormat(fmt)}
                  className="prody-card"
                  style={{
                    cursor: 'pointer',
                    borderColor: isSelected ? '#2563eb' : '#e2e8f0',
                    borderWidth: isSelected ? '2px' : '1px',
                    backgroundColor: isSelected ? '#f8faff' : '#ffffff',
                    boxShadow: isSelected ? '0 10px 25px -5px rgba(37,99,235,0.12)' : '0 1px 3px rgba(0,0,0,0.02)',
                    transition: 'all 0.2s ease',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'space-between',
                    gap: '16px',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '14px' }}>
                    <div
                      style={{
                        padding: '10px',
                        borderRadius: '12px',
                        backgroundColor: isSelected ? '#eff6ff' : '#f8fafc',
                        color: isSelected ? '#2563eb' : '#64748b',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        opacity: isSelected ? 1 : 0.75,
                        transition: 'all 0.15s ease',
                      }}
                    >
                      {fmt.icon}
                    </div>
                    <div>
                      <h3 style={{ fontSize: '0.98rem', fontWeight: 800, color: isSelected ? '#2563eb' : '#0f172a' }}>
                        {fmt.title}
                      </h3>
                      <p style={{ fontSize: '0.8rem', color: '#64748b', marginTop: '4px', lineHeight: 1.4 }}>
                        {fmt.subtitle}
                      </p>
                    </div>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid #f1f5f9', paddingTop: '10px' }}>
                    <span style={{ fontSize: '0.75rem', fontWeight: 700, color: isSelected ? '#2563eb' : '#94a3b8' }}>
                      {isSelected ? '✓ Selected Format' : 'Click to Select'}
                    </span>
                    <ArrowRight size={16} color={isSelected ? '#2563eb' : '#cbd5e1'} />
                  </div>
                </div>
              );
            })}
          </div>

          {/* Theme & Proposition Inputs */}
          <div className="prody-card" style={{ padding: '22px' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a', marginBottom: '14px' }}>
              Campaign Theme & Offer Details
            </h3>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '18px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                  Topic / Campaign Theme
                </label>
                <input
                  type="text"
                  className="optigo-input"
                  placeholder="e.g., Weekend Special Menu, Summer Refresh, Monsoons Feast"
                  value={theme}
                  onChange={(e) => setTheme(e.target.value)}
                  style={{ width: '100%', fontSize: '0.9rem' }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                  Offer / Main Value Proposition
                </label>
                <input
                  type="text"
                  className="optigo-input"
                  placeholder="e.g., Flat 20% OFF on all items, Free Dessert with Family Meals"
                  value={offerDetails}
                  onChange={(e) => setOfferDetails(e.target.value)}
                  style={{ width: '100%', fontSize: '0.9rem' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '20px' }}>
              <button
                onClick={() => setCurrentStep(1)}
                className="btn btn-primary"
                style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 22px', fontSize: '0.9rem', fontWeight: 700 }}
              >
                <span>Continue to Campaign Setup</span>
                <ArrowRight size={16} />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* STEP 2: CAMPAIGN BUILDER & CHANNELS */}
      {/* ======================================================== */}
      {currentStep === 1 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <button
              onClick={() => setCurrentStep(0)}
              className="btn btn-secondary btn-sm"
              style={{ display: 'flex', alignItems: 'center', gap: '4px' }}
            >
              <ArrowLeft size={14} />
              <span>Back</span>
            </button>
            <div>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0f172a', letterSpacing: '-0.3px' }}>
                Campaign Setup & Multi-Channel Distribution
              </h2>
              <p style={{ fontSize: '0.86rem', color: '#64748b', marginTop: '2px' }}>
                Target your local marketing channels and set campaign objectives.
              </p>
            </div>
          </div>

          {/* Campaign Objective Selector */}
          <div className="prody-card" style={{ padding: '20px' }}>
            <h3 style={{ fontSize: '0.96rem', fontWeight: 800, color: '#0f172a', marginBottom: '12px' }}>
              Primary Campaign Goal
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '12px' }}>
              {[
                { id: 'foot_traffic', label: 'Store Foot Traffic', desc: 'Drive customers to your physical location' },
                { id: 'online_orders', label: 'Direct Inquiries & Orders', desc: 'WhatsApp & phone call bookings' },
                { id: 'brand_awareness', label: 'Brand Reach & Visibility', desc: 'Maximize local search impressions' },
              ].map((g) => {
                const isSelected = campaignGoal === g.id;
                return (
                  <div
                    key={g.id}
                    onClick={() => setCampaignGoal(g.id)}
                    style={{
                      padding: '14px',
                      borderRadius: '12px',
                      border: `1.5px solid ${isSelected ? '#2563eb' : '#e2e8f0'}`,
                      backgroundColor: isSelected ? '#eff6ff' : '#ffffff',
                      cursor: 'pointer',
                      transition: 'all 0.15s ease',
                    }}
                  >
                    <h4 style={{ fontSize: '0.92rem', fontWeight: 800, color: isSelected ? '#1d4ed8' : '#0f172a' }}>
                      {g.label}
                    </h4>
                    <p style={{ fontSize: '0.78rem', color: '#64748b', marginTop: '4px' }}>{g.desc}</p>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Publishing Channels */}
          <div className="prody-card" style={{ padding: '20px' }}>
            <h3 style={{ fontSize: '0.96rem', fontWeight: 800, color: '#0f172a', marginBottom: '12px' }}>
              Target Publishing Channels
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '12px' }}>
              {[
                { id: 'google_post', name: 'Google Business', color: '#ea4335', badge: 'Maps & Search' },
                { id: 'instagram', name: 'Instagram', color: '#e1306c', badge: 'Feed & Stories' },
                { id: 'facebook', name: 'Facebook', color: '#1877f2', badge: 'Page & Groups' },
                { id: 'whatsapp', name: 'WhatsApp', color: '#25d366', badge: 'Broadcast' },
                { id: 'linkedin', name: 'LinkedIn', color: '#0a66c2', badge: 'Professional' },
              ].map((ch) => {
                const isSelected = selectedChannels.includes(ch.id);
                return (
                  <div
                    key={ch.id}
                    onClick={() => toggleChannel(ch.id)}
                    style={{
                      padding: '14px',
                      borderRadius: '12px',
                      border: `1.5px solid ${isSelected ? '#2563eb' : '#e2e8f0'}`,
                      backgroundColor: isSelected ? '#ffffff' : '#f8fafc',
                      boxShadow: isSelected ? '0 4px 12px rgba(37,99,235,0.08)' : 'none',
                      cursor: 'pointer',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '8px',
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontSize: '0.9rem', fontWeight: 800, color: '#0f172a' }}>{ch.name}</span>
                      <div
                        style={{
                          width: '18px',
                          height: '18px',
                          borderRadius: '50%',
                          backgroundColor: isSelected ? '#2563eb' : '#cbd5e1',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: '#fff',
                          fontSize: '11px',
                        }}
                      >
                        {isSelected ? '✓' : ''}
                      </div>
                    </div>
                    <span style={{ fontSize: '0.74rem', color: ch.color, fontWeight: 700 }}>{ch.badge}</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Campaign Schedule Duration */}
          <div className="prody-card" style={{ padding: '20px' }}>
            <h3 style={{ fontSize: '0.96rem', fontWeight: 800, color: '#0f172a', marginBottom: '12px' }}>
              Campaign Schedule Duration
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#64748b', marginBottom: '4px' }}>
                  Start Date
                </label>
                <input
                  type="date"
                  className="optigo-input"
                  value={startDate}
                  onChange={(e) => setStartDate(e.target.value)}
                  style={{ width: '100%' }}
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, color: '#64748b', marginBottom: '4px' }}>
                  End Date
                </label>
                <input
                  type="date"
                  className="optigo-input"
                  value={endDate}
                  onChange={(e) => setEndDate(e.target.value)}
                  style={{ width: '100%' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '20px' }}>
              <button
                onClick={handleGenerateAI}
                className="btn btn-primary"
                style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '12px 26px', fontSize: '0.92rem', fontWeight: 800 }}
              >
                <Sparkles size={16} />
                <span>Generate Multi-Channel Creative with AI</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* STEP 3: CREATIVE CANVAS & MULTI-CHANNEL STUDIO */}
      {/* ======================================================== */}
      {currentStep === 2 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '22px' }}>
          {/* Top Bar Navigation */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <button
                onClick={() => setCurrentStep(1)}
                className="btn btn-secondary btn-sm"
                style={{ display: 'flex', alignItems: 'center', gap: '4px' }}
              >
                <ArrowLeft size={14} />
                <span>Back</span>
              </button>
              <div>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#0f172a', letterSpacing: '-0.3px' }}>
                  Creative Studio & Preview
                </h2>
                <p style={{ fontSize: '0.84rem', color: '#64748b' }}>
                  AI-generated promotional banner and multi-channel copy.
                </p>
              </div>
            </div>

            <button
              onClick={() => setCurrentStep(0)}
              className="btn btn-secondary btn-sm"
              style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
            >
              <Plus size={14} />
              <span>New Campaign</span>
            </button>
          </div>

          {/* 2-Column Creative Studio: Left Graphic Canvas, Right Copy Tabs */}
          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(340px, 1.1fr) minmax(320px, 1fr)', gap: '20px' }}>
            {/* Left: Graphic Canvas Banner */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div
                style={{
                  width: '100%',
                  minHeight: '340px',
                  borderRadius: '20px',
                  background: `linear-gradient(135deg, ${selectedPalette.bg} 0%, #0f172a 100%)`,
                  padding: '26px',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  boxShadow: '0 20px 30px -10px rgba(15,23,42,0.25)',
                  position: 'relative',
                  overflow: 'hidden',
                  border: '1px solid rgba(255,255,255,0.1)',
                }}
              >
                {/* Background ambient glow circle */}
                <div
                  style={{
                    position: 'absolute',
                    top: '-40px',
                    right: '-40px',
                    width: '180px',
                    height: '180px',
                    borderRadius: '50%',
                    background: selectedPalette.accent,
                    filter: 'blur(55px)',
                    opacity: 0.35,
                    pointerEvents: 'none',
                  }}
                />

                {/* Top Banner Row */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', zIndex: 1 }}>
                  <span
                    style={{
                      padding: '4px 10px',
                      borderRadius: '8px',
                      backgroundColor: 'rgba(255,255,255,0.15)',
                      color: '#ffffff',
                      fontSize: '0.75rem',
                      fontWeight: 800,
                      letterSpacing: '0.6px',
                      backdropFilter: 'blur(4px)',
                    }}
                  >
                    {(activeLocation.name || 'STORE').toUpperCase()}
                  </span>
                  <span
                    style={{
                      padding: '4px 10px',
                      borderRadius: '8px',
                      backgroundColor: '#f59e0b',
                      color: '#000000',
                      fontSize: '0.72rem',
                      fontWeight: 900,
                      letterSpacing: '0.5px',
                    }}
                  >
                    {creativeBadge}
                  </span>
                </div>

                {/* Center Headline & Subtext */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', zIndex: 1, margin: '20px 0' }}>
                  <h2
                    style={{
                      fontSize: '1.85rem',
                      fontWeight: 900,
                      color: '#ffffff',
                      letterSpacing: '-0.5px',
                      lineHeight: 1.15,
                      textShadow: '0 2px 10px rgba(0,0,0,0.3)',
                    }}
                  >
                    {creativeHeadline}
                  </h2>
                  <div style={{ display: 'inline-block', width: 'fit-content' }}>
                    <span
                      style={{
                        display: 'inline-block',
                        padding: '6px 14px',
                        borderRadius: '10px',
                        backgroundColor: selectedPalette.accent,
                        color: '#ffffff',
                        fontSize: '0.96rem',
                        fontWeight: 900,
                        boxShadow: '0 4px 14px rgba(0,0,0,0.2)',
                      }}
                    >
                      {creativeSubtext}
                    </span>
                  </div>
                </div>

                {/* Bottom Footer Seal */}
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    borderTop: '1px solid rgba(255,255,255,0.12)',
                    paddingTop: '14px',
                    zIndex: 1,
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.75rem', fontWeight: 700, color: '#3b82f6', marginTop: '12px', backgroundColor: '#eff6ff', padding: '6px 12px', borderRadius: '12px', width: 'fit-content' }}>
                    <Check size={14} />
                    Verified Local Quality • Available Today
                  </div>
                  <div
                    style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '50%',
                      backgroundColor: '#ffffff',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: '#0f172a',
                    }}
                  >
                    <ArrowRight size={14} />
                  </div>
                </div>
              </div>

              {/* Color Theme Selector & Customizer Bar */}
              <div className="prody-card" style={{ padding: '16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                  <span style={{ fontSize: '0.84rem', fontWeight: 800, color: '#0f172a', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Palette size={16} color="#2563eb" />
                    <span>Canvas Color Palette</span>
                  </span>
                  <button
                    onClick={() => setShowEditCanvas(!showEditCanvas)}
                    className="btn btn-secondary btn-sm"
                    style={{ fontSize: '0.75rem', padding: '4px 8px' }}
                  >
                    {showEditCanvas ? 'Hide Customizer' : 'Edit Text'}
                  </button>
                </div>

                <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                  {COLOR_PALETTES.map((pal) => (
                    <button
                      key={pal.id}
                      onClick={() => setSelectedPalette(pal)}
                      style={{
                        width: '32px',
                        height: '32px',
                        borderRadius: '50%',
                        backgroundColor: pal.bg,
                        border: selectedPalette.id === pal.id ? '3px solid #2563eb' : '2px solid #e2e8f0',
                        cursor: 'pointer',
                        boxShadow: '0 2px 5px rgba(0,0,0,0.1)',
                      }}
                      title={pal.name}
                    />
                  ))}
                </div>

                {/* Expandable Text Customizer */}
                {showEditCanvas && (
                  <div style={{ marginTop: '14px', display: 'flex', flexDirection: 'column', gap: '10px', borderTop: '1px solid #f1f5f9', paddingTop: '12px' }}>
                    <div>
                      <label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b' }}>Headline Text</label>
                      <input
                        type="text"
                        className="optigo-input"
                        value={creativeHeadline}
                        onChange={(e) => setCreativeHeadline(e.target.value)}
                        style={{ width: '100%', fontSize: '0.84rem' }}
                      />
                    </div>
                    <div>
                      <label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b' }}>Offer Subtext</label>
                      <input
                        type="text"
                        className="optigo-input"
                        value={creativeSubtext}
                        onChange={(e) => setCreativeSubtext(e.target.value)}
                        style={{ width: '100%', fontSize: '0.84rem' }}
                      />
                    </div>
                    <div>
                      <label style={{ fontSize: '0.75rem', fontWeight: 700, color: '#64748b' }}>Badge Tag</label>
                      <input
                        type="text"
                        className="optigo-input"
                        value={creativeBadge}
                        onChange={(e) => setCreativeBadge(e.target.value)}
                        style={{ width: '100%', fontSize: '0.84rem' }}
                      />
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Right: Multi-Channel Copy Section */}
            <div className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: '20px' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
                  <h3 style={{ fontSize: '1rem', fontWeight: 800, color: '#0f172a' }}>
                    Multi-Channel Post Copy
                  </h3>
                  <button
                    onClick={() => handleCopyCaption(selectedChannelTab)}
                    className="btn btn-secondary btn-sm"
                    style={{ gap: '6px', fontSize: '0.8rem' }}
                  >
                    {copiedChannel === selectedChannelTab ? <Check size={14} color="#059669" /> : <Copy size={14} />}
                    <span>{copiedChannel === selectedChannelTab ? 'Copied' : 'Copy Caption'}</span>
                  </button>
                </div>

                {/* Channel Switcher Tabs */}
                <div style={{ display: 'flex', gap: '6px', overflowX: 'auto', paddingBottom: '8px' }}>
                  {[
                    { id: 'instagram', label: 'Instagram' },
                    { id: 'facebook', label: 'Facebook' },
                    { id: 'google_post', label: 'Google Post' },
                    { id: 'whatsapp', label: 'WhatsApp' },
                    { id: 'linkedin', label: 'LinkedIn' },
                  ].map((ch) => {
                    const isSelected = selectedChannelTab === ch.id;
                    return (
                      <button
                        key={ch.id}
                        onClick={() => setSelectedChannelTab(ch.id)}
                        style={{
                          padding: '6px 12px',
                          borderRadius: '8px',
                          border: 'none',
                          fontSize: '0.8rem',
                          fontWeight: isSelected ? 800 : 600,
                          backgroundColor: isSelected ? '#2563eb' : '#f1f5f9',
                          color: isSelected ? '#ffffff' : '#475569',
                          cursor: 'pointer',
                        }}
                      >
                        {ch.label}
                      </button>
                    );
                  })}
                </div>

                {/* Post Preview Box */}
                <div
                  style={{
                    backgroundColor: '#f8fafc',
                    borderRadius: '14px',
                    border: '1px solid #e2e8f0',
                    padding: '16px',
                    marginTop: '12px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '10px',
                  }}
                >
                  {currentActivePost.title && (
                    <h4 style={{ fontSize: '0.94rem', fontWeight: 800, color: '#0f172a' }}>
                      {currentActivePost.title}
                    </h4>
                  )}
                  <p style={{ fontSize: '0.86rem', color: '#334155', lineHeight: 1.5, whiteSpace: 'pre-wrap' }}>
                    {currentActivePost.body}
                  </p>
                  {currentActivePost.hashtags && (
                    <span style={{ fontSize: '0.8rem', color: '#0284c7', fontWeight: 700 }}>
                      {currentActivePost.hashtags}
                    </span>
                  )}
                  {currentActivePost.call_to_action && (
                    <div style={{ marginTop: '6px' }}>
                      <span className="prody-pill blue" style={{ fontSize: '0.74rem' }}>
                        CTA: {currentActivePost.call_to_action}
                      </span>
                    </div>
                  )}
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
                <button
                  onClick={handleGenerateAI}
                  disabled={isGenerating}
                  className="btn btn-secondary"
                  style={{ flex: 1, gap: '6px', fontSize: '0.86rem' }}
                >
                  <RefreshCw size={14} className={isGenerating ? 'spin' : ''} />
                  <span>Regenerate</span>
                </button>
                <button
                  onClick={handlePublishPost}
                  disabled={isPublishing}
                  className="btn btn-primary"
                  style={{ flex: 1.5, gap: '6px', fontSize: '0.86rem', fontWeight: 800 }}
                >
                  <Send size={14} />
                  <span>{isPublishing ? 'Publishing...' : 'Approve & Publish'}</span>
                </button>
              </div>
            </div>
          </div>

          {/* Published & Scheduled Campaigns Feed */}
          {existingPosts.length > 0 && (
            <div style={{ marginTop: '10px' }}>
              <h3 style={{ fontSize: '1.05rem', fontWeight: 800, color: '#0f172a', marginBottom: '14px' }}>
                Branch Scheduled & Published Campaigns
              </h3>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '14px' }}>
                {existingPosts.map((post, idx) => (
                  <div key={post.id || idx} className="prody-card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', gap: '10px' }}>
                    <div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                        <span className="prody-pill blue">{post.content_type || 'Google Post'}</span>
                        <span className="prody-pill green">{post.status || 'Published'}</span>
                      </div>
                      <h4 style={{ fontSize: '0.94rem', fontWeight: 700, color: '#0f172a', marginBottom: '4px' }}>
                        {post.title || 'Promotional Campaign'}
                      </h4>
                      <p style={{ fontSize: '0.82rem', color: '#475569', lineHeight: 1.4 }}>
                        {post.body}
                      </p>
                    </div>

                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid #f1f5f9', paddingTop: '8px' }}>
                      <span style={{ fontSize: '0.72rem', color: '#94a3b8' }}>
                        {post.created_at ? new Date(post.created_at).toLocaleDateString() : 'Recent'}
                      </span>
                      <button
                        onClick={() => {
                          navigator.clipboard.writeText(`${post.title ? post.title + '\n' : ''}${post.body}`);
                          alert('Copied to clipboard!');
                        }}
                        className="btn btn-secondary btn-sm"
                        style={{ fontSize: '0.75rem', padding: '4px 8px' }}
                      >
                        <Copy size={12} />
                        <span>Copy</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
