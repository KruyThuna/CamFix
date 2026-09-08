import { api } from './client';
import type { Job, JobInput, JobStatus } from './types';

export interface JobFilters {
  status?: JobStatus | '';
  technicianId?: number | '';
  q?: string;
}

export async function listJobs(f: JobFilters = {}): Promise<Job[]> {
  const params: Record<string, string | number> = {};
  if (f.status) params.status = f.status;
  if (f.technicianId) params.technicianId = f.technicianId;
  if (f.q) params.q = f.q;
  const { data } = await api.get<Job[]>('/api/admin/jobs', { params });
  return data;
}

export async function getJob(id: number): Promise<Job> {
  const { data } = await api.get<Job>(`/api/admin/jobs/${id}`);
  return data;
}

export async function createJob(input: JobInput): Promise<Job> {
  const { data } = await api.post<Job>('/api/admin/jobs', input);
  return data;
}

export async function updateJob(id: number, input: JobInput): Promise<Job> {
  const { data } = await api.put<Job>(`/api/admin/jobs/${id}`, input);
  return data;
}

export async function assignJob(id: number, technicianId: number): Promise<Job> {
  const { data } = await api.post<Job>(`/api/admin/jobs/${id}/assign`, { technicianId });
  return data;
}

export async function changeJobStatus(id: number, status: JobStatus): Promise<Job> {
  const { data } = await api.post<Job>(`/api/admin/jobs/${id}/status`, { status });
  return data;
}

export async function cancelJob(id: number): Promise<Job> {
  const { data } = await api.post<Job>(`/api/admin/jobs/${id}/cancel`, {});
  return data;
}
