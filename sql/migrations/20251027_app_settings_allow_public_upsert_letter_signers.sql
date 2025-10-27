-- Allow public upsert only for key='letter_signers' in app_settings

drop policy if exists app_settings_upsert_letter_signers_public on public.app_settings;
create policy app_settings_upsert_letter_signers_public on public.app_settings
  for insert to public
  with check (key = 'letter_signers');

drop policy if exists app_settings_update_letter_signers_public on public.app_settings;
create policy app_settings_update_letter_signers_public on public.app_settings
  for update to public
  using (key = 'letter_signers')
  with check (key = 'letter_signers');
