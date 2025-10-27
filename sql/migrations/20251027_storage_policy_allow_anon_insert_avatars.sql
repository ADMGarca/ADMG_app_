-- Allow anonymous (anon) and authenticated clients to upload into the
-- public 'avatars' bucket, but only under the members/ or users/ prefixes.
-- This is useful when your app does not use Supabase Auth for login.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Anon+Auth insert avatars (prefix)'
  ) THEN
    CREATE POLICY "Anon+Auth insert avatars (prefix)" ON storage.objects
      FOR INSERT
      WITH CHECK (
        bucket_id = 'avatars'
        AND (name LIKE 'members/%' OR name LIKE 'users/%')
      );
  END IF;
END $$;
