"use client";

import { useState } from "react";
import {
  Folder,
  Upload,
  Search,
  LayoutGrid,
  List,
  Settings,
  Crown,
  LogOut,
  Plus,
  Home,
  Star,
  Trash2,
  Share2,
  Moon,
  Sun,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FileTypeIcon } from "@/lib/file-icons";
import { formatBytes, formatDate, cn } from "@/lib/utils";
import type { FileItem, ViewMode } from "@/types";

// Demo data — gerçek backend gelince API'den gelecek
const DEMO_FILES: FileItem[] = [
  {
    id: "1",
    name: "Projeler",
    type: "folder",
    size: 0,
    path: "/Projeler",
    parentId: null,
    isFolder: true,
    isPublic: false,
    isLiked: false,
    likeCount: 0,
    downloadCount: 0,
    createdAt: "2026-10-20T10:00:00Z",
    updatedAt: "2026-10-28T14:30:00Z",
    ownerId: "u1",
  },
  {
    id: "2",
    name: "tasarim-mockup.png",
    type: "image",
    size: 2_450_000,
    path: "/tasarim-mockup.png",
    parentId: null,
    isFolder: false,
    isPublic: true,
    isLiked: true,
    likeCount: 12,
    downloadCount: 34,
    createdAt: "2026-10-25T09:15:00Z",
    updatedAt: "2026-10-25T09:15:00Z",
    ownerId: "u1",
  },
  {
    id: "3",
    name: "sunum-v2.pdf",
    type: "document",
    size: 5_120_000,
    path: "/sunum-v2.pdf",
    parentId: null,
    isFolder: false,
    isPublic: false,
    isLiked: false,
    likeCount: 3,
    downloadCount: 8,
    createdAt: "2026-10-27T16:40:00Z",
    updatedAt: "2026-10-27T16:40:00Z",
    ownerId: "u1",
  },
  {
    id: "4",
    name: "demo-video.mp4",
    type: "video",
    size: 48_200_000,
    path: "/demo-video.mp4",
    parentId: null,
    isFolder: false,
    isPublic: true,
    isLiked: false,
    likeCount: 5,
    downloadCount: 21,
    createdAt: "2026-10-22T11:00:00Z",
    updatedAt: "2026-10-22T11:00:00Z",
    ownerId: "u1",
  },
  {
    id: "5",
    name: "backup.zip",
    type: "archive",
    size: 120_000_000,
    path: "/backup.zip",
    parentId: null,
    isFolder: false,
    isPublic: false,
    isLiked: false,
    likeCount: 0,
    downloadCount: 2,
    createdAt: "2026-10-29T08:00:00Z",
    updatedAt: "2026-10-29T08:00:00Z",
    ownerId: "u1",
  },
  {
    id: "6",
    name: "app.tsx",
    type: "code",
    size: 12_400,
    path: "/app.tsx",
    parentId: null,
    isFolder: false,
    isPublic: false,
    isLiked: true,
    likeCount: 1,
    downloadCount: 0,
    createdAt: "2026-10-30T01:20:00Z",
    updatedAt: "2026-10-30T01:20:00Z",
    ownerId: "u1",
  },
];

export default function HomePage() {
  const [viewMode, setViewMode] = useState<ViewMode>("grid");
  const [search, setSearch] = useState("");
  const [dark, setDark] = useState(true);
  const [selected, setSelected] = useState<string | null>(null);

  const filtered = DEMO_FILES.filter((f) =>
    f.name.toLowerCase().includes(search.toLowerCase())
  );

  // Basit dark class toggle (ileride next-themes)
  if (typeof document !== "undefined") {
    document.documentElement.classList.toggle("dark", dark);
  }

  return (
    <div className="flex h-screen bg-background text-foreground">
      {/* Sidebar */}
      <aside className="hidden w-60 shrink-0 border-r border-border bg-card md:flex md:flex-col">
        <div className="flex h-14 items-center gap-2 border-b border-border px-4">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
            <Folder className="h-4 w-4" />
          </div>
          <span className="text-lg font-semibold tracking-tight">DosyaX</span>
        </div>

        <nav className="flex-1 space-y-1 p-3">
          <NavItem icon={Home} label="Ana Sayfa" active />
          <NavItem icon={Star} label="Favoriler" />
          <NavItem icon={Share2} label="Paylaşılanlar" />
          <NavItem icon={Trash2} label="Çöp Kutusu" />
          <div className="my-3 border-t border-border" />
          <NavItem icon={Crown} label="VIP Ol" className="text-amber-500" />
          <NavItem icon={Settings} label="Ayarlar" />
        </nav>

        <div className="border-t border-border p-3">
          <div className="flex items-center gap-3 rounded-lg bg-muted/50 p-2">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/20 text-sm font-medium text-primary">
              U
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium">Kullanıcı</p>
              <p className="truncate text-xs text-muted-foreground">ücretsiz plan</p>
            </div>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <LogOut className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </aside>

      {/* Main */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Header */}
        <header className="flex h-14 items-center gap-3 border-b border-border px-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Dosya veya klasör ara..."
              className="pl-9"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <div className="flex items-center gap-1">
            <Button
              variant={viewMode === "grid" ? "secondary" : "ghost"}
              size="icon"
              onClick={() => setViewMode("grid")}
            >
              <LayoutGrid className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === "list" ? "secondary" : "ghost"}
              size="icon"
              onClick={() => setViewMode("list")}
            >
              <List className="h-4 w-4" />
            </Button>
          </div>

          <Button variant="ghost" size="icon" onClick={() => setDark((d) => !d)}>
            {dark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
          </Button>

          <Button className="gap-2">
            <Upload className="h-4 w-4" />
            Yükle
          </Button>
          <Button variant="outline" size="icon">
            <Plus className="h-4 w-4" />
          </Button>
        </header>

        {/* Content */}
        <main className="flex-1 overflow-auto p-4 md:p-6">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h1 className="text-xl font-semibold">Dosyalarım</h1>
              <p className="text-sm text-muted-foreground">
                {filtered.length} öğe
              </p>
            </div>
          </div>

          {viewMode === "grid" ? (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6">
              {filtered.map((file) => (
                <button
                  key={file.id}
                  onClick={() => setSelected(file.id)}
                  className={cn(
                    "group flex flex-col items-center gap-2 rounded-xl border border-transparent p-3 text-center transition-all hover:border-border hover:bg-accent/50",
                    selected === file.id && "border-primary bg-primary/5"
                  )}
                >
                  <div className="flex h-16 w-16 items-center justify-center rounded-xl bg-muted/60 transition-colors group-hover:bg-muted">
                    <FileTypeIcon type={file.type} size={32} />
                  </div>
                  <div className="w-full">
                    <p className="truncate text-sm font-medium">{file.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {file.isFolder ? "Klasör" : formatBytes(file.size)}
                    </p>
                  </div>
                </button>
              ))}
            </div>
          ) : (
            <div className="overflow-hidden rounded-xl border border-border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/40 text-left text-muted-foreground">
                    <th className="px-4 py-3 font-medium">Ad</th>
                    <th className="hidden px-4 py-3 font-medium sm:table-cell">Boyut</th>
                    <th className="hidden px-4 py-3 font-medium md:table-cell">Değiştirilme</th>
                    <th className="px-4 py-3 font-medium">Durum</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((file) => (
                    <tr
                      key={file.id}
                      onClick={() => setSelected(file.id)}
                      className={cn(
                        "cursor-pointer border-b border-border last:border-0 hover:bg-accent/40",
                        selected === file.id && "bg-primary/5"
                      )}
                    >
                      <td className="flex items-center gap-3 px-4 py-3">
                        <FileTypeIcon type={file.type} size={20} />
                        <span className="font-medium">{file.name}</span>
                      </td>
                      <td className="hidden px-4 py-3 text-muted-foreground sm:table-cell">
                        {file.isFolder ? "—" : formatBytes(file.size)}
                      </td>
                      <td className="hidden px-4 py-3 text-muted-foreground md:table-cell">
                        {formatDate(file.updatedAt)}
                      </td>
                      <td className="px-4 py-3">
                        {file.isPublic && (
                          <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 text-xs text-emerald-600 dark:text-emerald-400">
                            Public
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}

function NavItem({
  icon: Icon,
  label,
  active,
  className,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  active?: boolean;
  className?: string;
}) {
  return (
    <button
      className={cn(
        "flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors",
        active
          ? "bg-primary/10 font-medium text-primary"
          : "text-muted-foreground hover:bg-accent hover:text-foreground",
        className
      )}
    >
      <Icon className="h-4 w-4 shrink-0" />
      {label}
    </button>
  );
}
