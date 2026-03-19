-- Soul App — Initial Schema
-- Run this in the Supabase SQL editor

-- =====================
-- EXTENSIONS
-- =====================
create extension if not exists "uuid-ossp";

-- =====================
-- TABLES
-- =====================

-- Users (mirrors auth.users)
create table public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  username    text unique not null,
  full_name   text not null,
  avatar_url  text,
  bio         text,
  created_at  timestamptz default now() not null
);

-- Projects
create table public.projects (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references public.users(id) on delete cascade,
  title           text not null,
  description     text not null default '',
  status          text not null default 'active' check (status in ('active', 'paused', 'completed')),
  start_date      date not null default current_date,
  cover_image_url text,
  created_at      timestamptz default now() not null
);

-- Updates
create table public.updates (
  id          uuid primary key default uuid_generate_v4(),
  project_id  uuid not null references public.projects(id) on delete cascade,
  user_id     uuid not null references public.users(id) on delete cascade,
  text        text not null default '',
  media_url   text,
  media_type  text not null default 'none' check (media_type in ('photo', 'video', 'none')),
  created_at  timestamptz default now() not null
);

-- Friendships
create table public.friendships (
  id            uuid primary key default uuid_generate_v4(),
  requester_id  uuid not null references public.users(id) on delete cascade,
  addressee_id  uuid not null references public.users(id) on delete cascade,
  status        text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at    timestamptz default now() not null,
  unique (requester_id, addressee_id)
);

-- =====================
-- INDEXES
-- =====================
create index on public.projects (user_id);
create index on public.updates (project_id);
create index on public.updates (user_id);
create index on public.friendships (requester_id);
create index on public.friendships (addressee_id);
create index on public.users (username);

-- =====================
-- ROW LEVEL SECURITY
-- =====================

-- Enable RLS
alter table public.users enable row level security;
alter table public.projects enable row level security;
alter table public.updates enable row level security;
alter table public.friendships enable row level security;

-- USERS policies
create policy "Users can view all profiles"
  on public.users for select using (true);

create policy "Users can update own profile"
  on public.users for update using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.users for insert with check (auth.uid() = id);

-- PROJECTS policies
create policy "Projects are visible to friends and owner"
  on public.projects for select using (
    user_id = auth.uid() or
    exists (
      select 1 from public.friendships f
      where f.status = 'accepted' and (
        (f.requester_id = auth.uid() and f.addressee_id = user_id) or
        (f.addressee_id = auth.uid() and f.requester_id = user_id)
      )
    )
  );

create policy "Users can create own projects"
  on public.projects for insert with check (user_id = auth.uid());

create policy "Users can update own projects"
  on public.projects for update using (user_id = auth.uid());

create policy "Users can delete own projects"
  on public.projects for delete using (user_id = auth.uid());

-- UPDATES policies
create policy "Updates visible to friends and owner"
  on public.updates for select using (
    user_id = auth.uid() or
    exists (
      select 1 from public.friendships f
      where f.status = 'accepted' and (
        (f.requester_id = auth.uid() and f.addressee_id = user_id) or
        (f.addressee_id = auth.uid() and f.requester_id = user_id)
      )
    )
  );

create policy "Users can create own updates"
  on public.updates for insert with check (user_id = auth.uid());

create policy "Users can delete own updates"
  on public.updates for delete using (user_id = auth.uid());

-- FRIENDSHIPS policies
create policy "Users can view own friendships"
  on public.friendships for select using (
    requester_id = auth.uid() or addressee_id = auth.uid()
  );

create policy "Users can send friend requests"
  on public.friendships for insert with check (requester_id = auth.uid());

create policy "Addressee can update (accept) friendship"
  on public.friendships for update using (addressee_id = auth.uid());

create policy "Either party can delete friendship"
  on public.friendships for delete using (
    requester_id = auth.uid() or addressee_id = auth.uid()
  );

-- =====================
-- STORAGE BUCKETS
-- =====================

-- Create the project-media storage bucket
insert into storage.buckets (id, name, public) values ('project-media', 'project-media', true);

-- Storage policies
create policy "Anyone can view project media"
  on storage.objects for select using (bucket_id = 'project-media');

create policy "Authenticated users can upload media"
  on storage.objects for insert with check (
    bucket_id = 'project-media' and auth.role() = 'authenticated'
  );

create policy "Users can delete own media"
  on storage.objects for delete using (
    bucket_id = 'project-media' and auth.uid()::text = (storage.foldername(name))[1]
  );
