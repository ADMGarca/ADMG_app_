-- Create public bucket for user avatars (idempotent)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Add avatar_url column to usuario table if it doesn't exist
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'usuario' and column_name = 'avatar_url'
  ) then
    alter table public.usuario add column avatar_url text;
  end if;
end $$;

-- Storage RLS policies (idempotent creates)
-- Public read for avatars bucket
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'Public read avatars'
  ) then
    create policy "Public read avatars" on storage.objects
      for select using (bucket_id = 'avatars');
  end if;
end $$;

-- Authenticated users can upload to avatars bucket
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'Authenticated insert avatars'
  ) then
    create policy "Authenticated insert avatars" on storage.objects
      for insert with check (bucket_id = 'avatars' and auth.role() = 'authenticated');
  end if;
end $$;

-- Owners can update/delete their own files in avatars bucket
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'Owner modify avatars'
  ) then
    create policy "Owner modify avatars" on storage.objects
      for update using (bucket_id = 'avatars' and owner = auth.uid())
      with check (bucket_id = 'avatars' and owner = auth.uid());
  end if;
end $$;
