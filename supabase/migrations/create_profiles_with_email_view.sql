-- Create or replace the view to join profiles and auth.users
CREATE OR REPLACE VIEW public.profiles_with_email AS
SELECT
  p.*,
  u.email
FROM
  profiles p
  JOIN auth.users u ON p.id = u.id;

-- Grant SELECT permission on the view to the authenticated role
GRANT SELECT ON public.profiles_with_email TO authenticated; 