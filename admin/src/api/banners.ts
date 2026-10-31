import { api } from './client';

export interface AppBanner {
  id: number;
  title: string;
  subtitle: string | null;
  category: string | null;
  actionUrl: string | null;
  imageUrl: string | null;
  displayOrder: number;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export async function listBanners(): Promise<AppBanner[]> {
  const res = await api.get<AppBanner[]>('/api/admin/banners');
  return res.data;
}

export async function createBanner(formData: FormData): Promise<AppBanner> {
  const res = await api.post<AppBanner>('/api/admin/banners', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return res.data;
}

export async function updateBanner(
  id: number,
  formData: FormData
): Promise<AppBanner> {
  const res = await api.put<AppBanner>(`/api/admin/banners/${id}`, formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return res.data;
}

export async function deleteBanner(id: number): Promise<void> {
  await api.delete(`/api/admin/banners/${id}`);
}
