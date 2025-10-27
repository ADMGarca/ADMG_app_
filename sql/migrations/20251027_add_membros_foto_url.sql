-- Add foto_url column to membros if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'membros' AND column_name = 'foto_url'
  ) THEN
    ALTER TABLE public.membros ADD COLUMN foto_url text;
  END IF;
END $$;
