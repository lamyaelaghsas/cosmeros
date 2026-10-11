-- Cosmeros : schéma Supabase
-- À coller dans Supabase > SQL Editor, puis "Run".

-- ---------- Tables ----------

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9._]{3,30}$'),
  display_name text check (char_length(display_name) <= 50),
  bio text check (char_length(bio) <= 160),
  instagram text check (char_length(instagram) <= 30),
  theme text not null default 'nebuleuse',
  created_at timestamptz not null default now()
);

-- Cache des œuvres venues de TMDB / Deezer
create table public.media (
  id text primary key,                       -- ex. 'tmdb:movie:157336'
  type text not null check (type in ('film', 'serie', 'album')),
  title text not null,
  subtitle text,
  year text,
  image_url text,
  overview text,
  created_at timestamptz not null default now()
);

-- Le journal : une ligne par membre et par œuvre
create table public.entries (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  media_id text not null references public.media (id) on delete cascade,
  status text not null check (status in ('vu', 'a_voir')),
  rating numeric(2, 1) check (rating between 0.5 and 5),
  review text check (char_length(review) <= 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, media_id)
);
create index entries_user_updated on public.entries (user_id, updated_at desc);

create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table public.likes (
  user_id uuid not null references public.profiles (id) on delete cascade,
  entry_id bigint not null references public.entries (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, entry_id)
);

create table public.favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  media_id text not null references public.media (id) on delete cascade,
  position bigint not null default 0,
  primary key (user_id, media_id)
);

create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

create table public.reports (
  id bigint generated always as identity primary key,
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  entry_id bigint references public.entries (id) on delete set null,
  reported_user_id uuid references public.profiles (id) on delete set null,
  reason text not null check (char_length(reason) <= 1000),
  status text not null default 'ouvert',
  created_at timestamptz not null default now()
);

-- ---------- Création automatique du profil à l'inscription ----------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(lower(new.raw_user_meta_data ->> 'username'), 'membre_' || substr(new.id::text, 1, 8))
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- Sécurité (Row Level Security) ----------

alter table public.profiles enable row level security;
alter table public.media enable row level security;
alter table public.entries enable row level security;
alter table public.follows enable row level security;
alter table public.likes enable row level security;
alter table public.favorites enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;

create policy "profils lisibles" on public.profiles for select to authenticated using (true);
create policy "modifier son profil" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy "oeuvres lisibles" on public.media for select to authenticated using (true);
create policy "ajouter une oeuvre" on public.media for insert to authenticated with check (true);
create policy "mettre a jour une oeuvre" on public.media for update to authenticated using (true) with check (true);

create policy "journal lisible" on public.entries for select to authenticated using (true);
create policy "ecrire son journal" on public.entries for insert to authenticated with check (user_id = auth.uid());
create policy "modifier son journal" on public.entries for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "supprimer de son journal" on public.entries for delete to authenticated using (user_id = auth.uid());

create policy "abonnements lisibles" on public.follows for select to authenticated using (true);
create policy "suivre" on public.follows for insert to authenticated with check (follower_id = auth.uid());
create policy "ne plus suivre" on public.follows for delete to authenticated using (follower_id = auth.uid());

create policy "likes lisibles" on public.likes for select to authenticated using (true);
create policy "liker" on public.likes for insert to authenticated with check (user_id = auth.uid());
create policy "unliker" on public.likes for delete to authenticated using (user_id = auth.uid());

create policy "favoris lisibles" on public.favorites for select to authenticated using (true);
create policy "gerer ses favoris" on public.favorites for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "voir ses blocages" on public.blocks for select to authenticated using (blocker_id = auth.uid());
create policy "bloquer" on public.blocks for insert to authenticated with check (blocker_id = auth.uid());
create policy "debloquer" on public.blocks for delete to authenticated using (blocker_id = auth.uid());

create policy "signaler" on public.reports for insert to authenticated with check (reporter_id = auth.uid());
