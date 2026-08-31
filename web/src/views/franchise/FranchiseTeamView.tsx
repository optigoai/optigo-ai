// ==================================================
// OptigoAI Enterprise — Prody Light Team View
// ==================================================

import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useFranchise } from '../../context/FranchiseContext';
import {
  Users,
  Plus,
  X,
  Check,
} from 'lucide-react';
import { TeamMember } from '../../types';

export const FranchiseTeamView: React.FC = () => {
  const { user } = useAuth();
  const { locations } = useFranchise();

  const [team, setTeam] = useState<TeamMember[]>([
    {
      id: 'm-1',
      name: user?.full_name || 'Ahmed Yazeen',
      email: user?.email || 'director@casaraza.com',
      role: 'Franchise Owner',
      assigned_regions: ['All Regions'],
      assigned_locations: ['All Locations'],
      status: 'Active',
    },
  ]);

  const [isInviteOpen, setIsInviteOpen] = useState(false);
  const [inviteName, setInviteName] = useState('');
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRole, setInviteRole] = useState<'Regional Director' | 'Store Manager'>('Store Manager');

  const handleInvite = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inviteName || !inviteEmail) return;

    setTeam((prev) => [
      ...prev,
      {
        id: `m-${Date.now()}`,
        name: inviteName,
        email: inviteEmail,
        role: inviteRole,
        assigned_regions: ['Primary Region'],
        assigned_locations: [locations[0]?.name || 'Primary Branch'],
        status: 'Invited',
      },
    ]);

    setIsInviteOpen(false);
    setInviteName('');
    setInviteEmail('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* 1. Entity Header */}
      <div className="entity-header-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div className="entity-icon-badge">
            <Users size={26} />
          </div>
          <div>
            <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: '#111827', lineHeight: 1.2 }}>
              Franchise Team & Permissions
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '6px' }}>
              <span className="prody-pill blue">{team.length} Active Accounts</span>
              <span className="prody-pill green">Role-based Access Control</span>
            </div>
          </div>
        </div>

        <button onClick={() => setIsInviteOpen(true)} className="btn btn-coral btn-sm" style={{ gap: '6px' }}>
          <Plus size={14} />
          <span>Invite Member</span>
        </button>
      </div>

      {/* 2. Table */}
      <div className="prody-card" style={{ padding: 0, overflow: 'hidden' }}>
        <div className="prody-table-wrapper" style={{ border: 'none', borderRadius: 0 }}>
          <table className="prody-table">
            <thead>
              <tr>
                <th>Member</th>
                <th>Role</th>
                <th>Regions</th>
                <th>Branches</th>
                <th>Status</th>
                <th style={{ textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {team.map((member) => (
                <tr key={member.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <div
                        style={{
                          width: '28px',
                          height: '28px',
                          borderRadius: '50%',
                          backgroundColor: '#E0F2FE',
                          color: '#0369A1',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          fontSize: '0.75rem',
                        }}
                      >
                        {member.name.substring(0, 2).toUpperCase()}
                      </div>
                      <div>
                        <div style={{ fontWeight: 700, color: '#111827' }}>{member.name}</div>
                        <div style={{ fontSize: '0.75rem', color: '#9CA3AF' }}>{member.email}</div>
                      </div>
                    </div>
                  </td>
                  <td><span className="prody-pill blue">{member.role}</span></td>
                  <td><span style={{ fontSize: '0.8rem', color: '#4B5563' }}>{member.assigned_regions.join(', ')}</span></td>
                  <td><span style={{ fontSize: '0.8rem', color: '#4B5563' }}>{member.assigned_locations.join(', ')}</span></td>
                  <td>
                    <span className={`prody-pill ${member.status === 'Active' ? 'green' : 'peach'}`}>
                      {member.status}
                    </span>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <button className="btn btn-secondary btn-sm">Edit</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Invite Modal */}
      {isInviteOpen && (
        <div className="modal-overlay" onClick={() => setIsInviteOpen(false)}>
          <div className="modal-container" onClick={(e) => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <h3 style={{ fontSize: '1.15rem', fontWeight: 800, color: '#111827' }}>Invite Team Member</h3>
              <button onClick={() => setIsInviteOpen(false)} style={{ background: 'transparent', border: 'none', color: '#9CA3AF', cursor: 'pointer' }}>
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleInvite} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div className="input-group">
                <label className="input-label">Full Name *</label>
                <input
                  type="text"
                  className="optigo-input"
                  placeholder="e.g. Ramesh Chandra"
                  value={inviteName}
                  onChange={(e) => setInviteName(e.target.value)}
                  required
                />
              </div>

              <div className="input-group">
                <label className="input-label">Business Email *</label>
                <input
                  type="email"
                  className="optigo-input"
                  placeholder="e.g. ramesh@company.com"
                  value={inviteEmail}
                  onChange={(e) => setInviteEmail(e.target.value)}
                  required
                />
              </div>

              <div className="input-group">
                <label className="input-label">Role</label>
                <select className="optigo-input" value={inviteRole} onChange={(e) => setInviteRole(e.target.value as any)}>
                  <option value="Regional Director">Regional Director</option>
                  <option value="Store Manager">Store Manager</option>
                </select>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '6px' }}>
                <button type="button" onClick={() => setIsInviteOpen(false)} className="btn btn-secondary btn-sm">Cancel</button>
                <button type="submit" className="btn btn-coral btn-sm">
                  <Check size={14} /> Send Invitation
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
