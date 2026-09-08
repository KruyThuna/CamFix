import { api } from './client';
import type {
  AccountStatus,
  ApprovalStatus,
  Technician,
  TechnicianInput,
  TechnicianLocation,
} from './types';

export interface TechnicianFilters {
  approval?: ApprovalStatus | '';
  account?: AccountStatus | '';
  category?: string;
  q?: string;
}

export async function listTechnicians(f: TechnicianFilters = {}): Promise<Technician[]> {
  const params: Record<string, string> = {};
  if (f.approval) params.approval = f.approval;
  if (f.account) params.account = f.account;
  if (f.category) params.category = f.category;
  if (f.q) params.q = f.q;
  const { data } = await api.get<Technician[]>('/api/admin/technicians', { params });
  return data;
}

export async function getTechnician(id: number): Promise<Technician> {
  const { data } = await api.get<Technician>(`/api/admin/technicians/${id}`);
  return data;
}

export async function createTechnician(input: TechnicianInput): Promise<Technician> {
  const { data } = await api.post<Technician>('/api/admin/technicians', input);
  return data;
}

export async function updateTechnician(
  id: number,
  input: TechnicianInput,
): Promise<Technician> {
  const { data } = await api.put<Technician>(`/api/admin/technicians/${id}`, input);
  return data;
}

export async function deleteTechnician(id: number): Promise<void> {
  await api.delete(`/api/admin/technicians/${id}`);
}

const action = (verb: string) => async (id: number, body?: unknown) => {
  const { data } = await api.post<Technician>(
    `/api/admin/technicians/${id}/${verb}`,
    body ?? {},
  );
  return data;
};

export const approveTechnician = action('approve');
export const suspendTechnician = action('suspend');
export const reactivateTechnician = action('reactivate');

export async function rejectTechnician(id: number, reason: string): Promise<Technician> {
  const { data } = await api.post<Technician>(`/api/admin/technicians/${id}/reject`, {
    reason,
  });
  return data;
}

export async function listTechnicianLocations(): Promise<TechnicianLocation[]> {
  const { data } = await api.get<TechnicianLocation[]>('/api/admin/technicians/locations');
  return data;
}
