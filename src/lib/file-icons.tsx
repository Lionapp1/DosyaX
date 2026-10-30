import {
  Folder,
  FileImage,
  FileVideo,
  FileAudio,
  FileText,
  FileArchive,
  FileCode,
  File,
  type LucideIcon,
} from "lucide-react";
import type { FileType } from "@/types";

const iconMap: Record<FileType, LucideIcon> = {
  folder: Folder,
  image: FileImage,
  video: FileVideo,
  audio: FileAudio,
  document: FileText,
  archive: FileArchive,
  code: FileCode,
  other: File,
};

const colorMap: Record<FileType, string> = {
  folder: "text-amber-500",
  image: "text-emerald-500",
  video: "text-rose-500",
  audio: "text-violet-500",
  document: "text-blue-500",
  archive: "text-orange-500",
  code: "text-cyan-500",
  other: "text-muted-foreground",
};

export function getFileIcon(type: FileType): LucideIcon {
  return iconMap[type] ?? File;
}

export function getFileIconColor(type: FileType): string {
  return colorMap[type] ?? "text-muted-foreground";
}

export function FileTypeIcon({
  type,
  className,
  size = 20,
}: {
  type: FileType;
  className?: string;
  size?: number;
}) {
  const Icon = getFileIcon(type);
  const color = getFileIconColor(type);
  return <Icon className={`${color} ${className ?? ""}`} size={size} />;
}
