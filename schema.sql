-- BreakLog data model reference.
--
-- Two stores exist today. The device holds the whole library as JSON in
-- SharedPreferences plus attachment files in app documents. The worker holds
-- one row per Google account in Turso. Shapes below are documentation: this
-- file is not a migration script, and nothing in the app runs it.
--
-- Section three is migration planned only. Nothing creates those tables yet.

-- ===========================================================================
-- Current: device storage
-- ===========================================================================
-- Keys are read and written by the repositories in lib/services. Every value
-- is JSON, loaded on app start and rewritten after each change.

-- breaklog_moves_v1 : array of moves (MoveRepository)
-- [
--   {
--     "id": "1760941234567890",        -- string, microseconds since epoch
--     "name": "Airflare",
--     "category": "Power",             -- a MoveCategory name, "" when unset
--     "difficulty": 3,                 -- integer 1..5, clamped while reading
--     "depth": "myVersion",            -- universal | myVersion | myCreation
--     "notes": "Drill from both sides",
--     "media": [ ...attachment ],      -- shared shape, see below
--     "learnedAt": "2026-10-20T04:30:00.000",
--     "favorite": false
--   }
-- ]

-- breaklog_categories_v1 : array of user move types (CategoryRepository)
-- [
--   { "name": "Toprock" },
--   { "name": "Footwork" },
--   { "name": "Power" },
--   { "name": "Freeze" },
--   { "name": "Combo" }
-- ]
-- Defaults ship with the app. Older storage held bare strings, and a bare
-- string still reads as a name.

-- breaklog_sets_v1 : array of routines (SetRepository)
-- [
--   {
--     "id": "1760941234567890",        -- string, microseconds since epoch
--     "name": "Round one",
--     "moveIds": ["1760941234567890"],
--     "createdAt": "2026-10-02T04:30:00.000",
--     "media": [ ...attachment ]
--   }
-- ]

-- breaklog_notes_v1 : array of journal notes (NoteRepository)
-- [
--   {
--     "id": "1760941234567890",        -- string, microseconds since epoch
--     "body": "Finally stuck the roundoff.",
--     "createdAt": "2026-10-20T04:30:00.000",   -- the day the note belongs to
--     "media": [ ...attachment ]
--   }
-- ]

-- The attachment shape is one model shared by moves, sets and notes
-- (MoveMedia, lib/models/media.dart):
-- {
--   "id": "1760941234567890",
--   "kind": "photo",                   -- link | video | record | photo
--   "value": "https://...",            -- link holds a URL, the rest hold a
--                                      -- path under breaklog_media, or a URL
--   "driveFileId": null                -- Drive copy id once the backup ran
-- }

-- Scalar device keys (AppState):
-- breaklog_started_v1          text   first run date sent when registering
-- breaklog_why_v1              text   why the user practices (onboarding)
-- breaklog_alias_v1            text   the name this device calls the account
-- breaklog_profile_updated_v1  text   local mirror of the last profile save
-- breaklog_beta_channel        bool   beta release channel

-- Attachment files: <app documents>/breaklog_media/<microseconds>.<ext>
-- MediaStore imports a picked file into that folder and deletes it when the
-- move, set or note carrying it is deleted.

-- ===========================================================================
-- Current: account storage (Turso, breaklog-api src/users.js)
-- ===========================================================================
-- One row per Google account. The account holds who the user is, not the
-- library, so nothing else is stored server side today.

create table if not exists users (
  user_id text primary key,            -- Google subject from the verified token
  email text,
  name text,
  picture text,                        -- profile photo URL
  alias text,                          -- trimmed to 60 characters
  started_at text,                     -- trimmed to 32 characters
  why text,                            -- trimmed to 500 characters
  created_at integer not null,         -- epoch ms, first sign in
  updated_at integer not null,         -- epoch ms, every write bumps this,
                                      -- including POST /auth/session
  profile_updated_at integer           -- epoch ms, bumped only by a POST /profile
                                      -- edit; null until the first edit
);

-- Rows older than started_at, why and profile_updated_at exist, so
-- ensureUsersSchema adds the missing columns with alter table after reading
-- pragma table_info on first use.
--
-- POST /profile refuses an edit with 429 until profile_updated_at is a week
-- old. POST /auth/session never moves that clock, and while the window is shut
-- it also stops returning the profile fields.

-- ===========================================================================
-- Planned: device data moving to the account (not created anywhere yet)
-- ===========================================================================
-- Moves, move types, sets and notes are device only. When they migrate they
-- land on this account, keyed by user_id, with the JSON fields above as
-- columns and one shared attachment table for the attachment shape:

-- create table if not exists moves (
--   user_id text not null,
--   id text not null,                  -- device id, microseconds since epoch
--   name text not null,
--   category text,
--   difficulty integer,                -- 1..5
--   depth text,                        -- universal | myVersion | myCreation
--   notes text,
--   learned_at text,
--   favorite integer,                  -- 0 | 1
--   primary key (user_id, id)
-- );
--
-- create table if not exists categories (
--   user_id text not null,
--   name text not null,
--   primary key (user_id, name)
-- );
--
-- create table if not exists sets (
--   user_id text not null,
--   id text not null,
--   name text not null,
--   created_at text not null,
--   primary key (user_id, id)
-- );
--
-- create table if not exists set_moves (       -- moveIds order matters
--   user_id text not null,
--   set_id text not null,
--   move_id text not null,
--   position integer not null,
--   primary key (user_id, set_id, position)
-- );
--
-- create table if not exists notes (
--   user_id text not null,
--   id text not null,
--   body text not null default '',
--   created_at text not null,          -- the day the note belongs to
--   primary key (user_id, id)
-- );
--
-- create table if not exists attachments (
--   user_id text not null,
--   owner_type text not null,          -- move | set | note
--   owner_id text not null,
--   id text not null,
--   kind text not null,                -- link | video | record | photo
--   value text not null,
--   drive_file_id text,
--   primary key (user_id, owner_type, owner_id, id)
-- );
