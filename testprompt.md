Build a small web app for splitting shared expenses among a group of friends
(think a minimal Splitwise).

Stack: Go backend (standard library preferred, minimal dependencies) and a
React frontend.

Users should be able to:

- Create a group and add members to it
- Record an expense: who paid, how much, and who it was split between
- See each member's current balance
- See a "settle up" view that tells everyone who should pay whom, using as
  few payments as reasonably possible

Data should persist across server restarts.
