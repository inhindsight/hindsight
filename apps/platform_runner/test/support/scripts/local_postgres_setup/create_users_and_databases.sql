--- This script is for setting up users and databases for local testing of the platform --

create user acquire_user with password 'acquire123';
create database acquire_view_state with owner acquire_user;

create user broadcast_user with password 'broadcast123';
create database broadcast_view_state with owner broadcast_user;

create user gather_user with password 'gather123';
create database gather_view_state with owner gather_user;

create user orchestrate_user with password 'orchestrate123';
create database orchestrate_view_state with owner orchestrate_user;

create user persist_user with password 'persist123';
create database persist_view_state with owner persist_user;

create user profile_user with password 'profile123';
create database profile_view_state with owner profile_user;

create user receive_user with password 'receive123';
create database receive_view_state with owner receive_user;
