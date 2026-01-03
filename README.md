# TheGame

This repository contains an Elixir-based dice and rules engine inspired by
Daggerheart-style mechanics, implemented with OTP principles and tested
using ExUnit.

## Structure

- `dice_roller/`
  Pure backend domain logic and OTP processes:
  - Dice rolling engine
  - Daggerheart Duality rules
  - Table / Check / Player state
  - GenServer orchestration
  - Deterministic tests

- `dice_web/` (coming next)
  Phoenix + LiveView frontend that uses the backend engine.

## Goals

- Practice real-world Elixir/OTP design
- Build a reusable game backend
- Showcase clean separation of domain logic and UI

## Status

Backend complete and tested.
Phoenix LiveView integration is the next step.

