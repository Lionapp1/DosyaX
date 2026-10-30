export type FileType =
  | "folder"
  | "image"
  | "video"
  | "audio"
  | "document"
  | "archive"
  | "code"
  | "other";

export interface FileItem {
  id: string;
  name: string;
  type: FileType;
  size: number;
  mimeType?: string;
  path: string;
  parentId: string | null;
  isFolder: boolean;
  isPublic: boolean;
  isLiked: boolean;
  likeCount: number;
  downloadCount: number;
  createdAt: string;
  updatedAt: string;
  ownerId: string;
  ownerName?: string;
  thumbnailUrl?: string;
  tags?: string[];
}

export interface User {
  id: string;
  email: string;
  username: string;
  displayName: string;
  avatarUrl?: string;
  isVip: boolean;
  isAdmin: boolean;
  storageUsed: number;
  storageLimit: number; // bytes, -1 = unlimited for VIP
  createdAt: string;
}

export interface ShareLink {
  id: string;
  fileId: string;
  token: string;
  password?: string;
  expiresAt?: string;
  maxDownloads?: number;
  downloadCount: number;
  createdAt: string;
}

export type ViewMode = "list" | "grid" | "gallery";

export type SortBy = "name" | "size" | "date" | "type";
export type SortOrder = "asc" | "desc";

export interface FileFilters {
  query?: string;
  type?: FileType | "all";
  sortBy: SortBy;
  sortOrder: SortOrder;
  onlyPublic?: boolean;
}
