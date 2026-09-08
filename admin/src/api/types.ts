export type ApprovalStatus = 'PENDING' | 'APPROVED' | 'REJECTED';
export type AccountStatus = 'ACTIVE' | 'SUSPENDED';
export type JobStatus =
  | 'REQUESTED'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED';

export const SERVICE_CATEGORIES = [
  'Air Conditioner',
  'Electrical',
  'Appliance Repair',
  'Motorcycle',
  'Car',
  'Water network',
] as const;

export interface Technician {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  category: string;
  serviceArea: string;
  about: string | null;
  openingHours: string | null;
  rating: number;
  ratingCount: number;
  approvalStatus: ApprovalStatus;
  accountStatus: AccountStatus;
  available: boolean;
  lastLat: number | null;
  lastLng: number | null;
  lastLocationAt: string | null;
  createdAt: string;
  approvedAt: string | null;
  rejectionReason: string | null;
}

export interface TechnicianLocation {
  id: number;
  name: string;
  category: string;
  lat: number;
  lng: number;
  available: boolean;
  lastLocationAt: string | null;
}

export interface TechnicianInput {
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  category: string;
  serviceArea: string;
  about?: string | null;
  openingHours?: string | null;
  rating?: number | null;
  available?: boolean | null;
}

export interface Job {
  id: number;
  customerName: string;
  customerPhone: string;
  customerUserId: number | null;
  category: string;
  description: string;
  address: string | null;
  lat: number | null;
  lng: number | null;
  status: JobStatus;
  technicianId: number | null;
  technicianName: string | null;
  technicianPhone: string | null;
  createdAt: string;
  scheduledAt: string | null;
  assignedAt: string | null;
  completedAt: string | null;
  notes: string | null;
}

export interface JobInput {
  customerName: string;
  customerPhone: string;
  customerUserId?: number | null;
  category: string;
  description: string;
  address?: string | null;
  lat?: number | null;
  lng?: number | null;
  scheduledAt?: string | null;
  notes?: string | null;
}

export interface DashboardStats {
  pendingTechnicians: number;
  activeTechnicians: number;
  suspendedTechnicians: number;
  openJobs: number;
  unassignedJobs: number;
  completedJobs: number;
}

export interface UserInfo {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  role: string;
  status: string;
  dateOfBirth: string | null;
}
