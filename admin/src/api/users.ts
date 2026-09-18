import { api } from './client';
import type { PasswordResetResult, UserInfo } from './types';

export interface UserFilters {
  role?: string;
  q?: string;
}

export async function listUsers(f: UserFilters = {}): Promise<UserInfo[]> {
  const params: Record<string, string> = {};
  if (f.role) params.role = f.role;
  if (f.q) params.q = f.q;
  const { data } = await api.get<UserInfo[]>('/api/admin/users', { params });
  return data;
}

export async function resetUserPassword(id: number): Promise<PasswordResetResult> {
  const { data } = await api.post<PasswordResetResult>(`/api/admin/users/${id}/reset-password`);
  return data;
}
