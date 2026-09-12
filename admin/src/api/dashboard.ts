import { api } from './client';
import type { DashboardStats } from './types';

export async function getStats(): Promise<DashboardStats> {
  const { data } = await api.get<DashboardStats>('/api/admin/stats');
  return data;
}
