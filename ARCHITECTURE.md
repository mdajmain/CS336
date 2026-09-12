# BuyMe Architecture

## Layers

- **`model`** (`com.buyme.model`) — plain data classes: `User`, `Auction`, `Bid`.
  No DB or servlet dependencies.
- **`dao`** (`com.buyme.dao`) — `UserDAO`, `AuctionDAO`, `BidDAO`. All JDBC access
  for the login/register/bid/create-auction flows goes through these, using
  `PreparedStatement`s throughout (no string-concatenated SQL).
- **`controller`** (`com.buyme.controller`) — `LoginServlet`, `LogoutServlet`,
  `RegisterServlet`, `CreateAuctionServlet`, `PlaceBidServlet`, and `AuthFilter`.
  All five servlets are registered via `@WebServlet` (no `web.xml`
  `<servlet-mapping>` entries).
- **JSPs** (`src/main/webapp`) — most pages render HTML directly and read the
  session for the logged-in `User`. A minority of pages (`browse.jsp`,
  `auction-details.jsp`, and about 35 others under `admin/`, `rep/`, `auction/`
  and the top level) still run their own inline JDBC instead of going through a
  DAO — see "Known architectural debt" below.

## Request-time access control: `AuthFilter`

`com.buyme.controller.AuthFilter` is a single `@WebFilter` that replaced ~40
copy-pasted per-page session-check scriptlets (each JSP used to open with its
own `User user = (User) session.getAttribute("user"); if (user == null || ...)`
block, with the exact wording, redirect target, and role check varying
slightly page to page).

It derives the required role from the request path:

| Path pattern | Required role |
|---|---|
| `/admin/*` | `admin` |
| `/rep/*` | `customer_rep` |
| `/my-auctions.jsp`, `/auction/my-auctions.jsp`, `/auction/create.jsp`, `/auction/edit.jsp`, `/auction/cancel.jsp`, `/auction/my-bids.jsp` | `end_user` |
| every other path listed in its `urlPatterns` | any logged-in user |

`index.jsp`, `login.jsp`, `register.jsp`, and three intentionally-public
per-auction pages (`auction/view.jsp`, `auction/bid-history.jsp`,
`auction/similar.jsp`) are **not** in the filter's `urlPatterns` — they were
public before the filter existed and must stay that way.

## Auth: password hashing

Passwords are stored as bcrypt hashes (`org.mindrot.jbcrypt`), not plaintext.
`UserDAO.register()` hashes on the way in; `UserDAO.login()` looks up the row
by username only, then verifies with `BCrypt.checkpw`. The login UX is
unchanged — users still type their plaintext password, only the at-rest
storage changed.

## The `place_bid` stored procedure

Bidding is proxy/auto-bidding, similar to eBay: a bidder sets a `maxBidLimit`
(a ceiling), and the visible `currentPrice` only rises as far as needed to
stay ahead of the next-best bid. `PlaceBidServlet` calls
`{CALL place_bid(?, ?, ?)}` with `(auctionID, buyerID, maxBidLimit)`.

Logic inside the procedure:

1. Reject if the bidder is the auction's own seller
   (`"Sellers cannot bid on their own items"`).
2. Reject if `maxBidLimit` is below `currentPrice + bidIncrement`
   (`"Bid must be at least current price plus increment"`).
   `PlaceBidServlet` matches on these exact substrings to show a friendly
   error, so the wording is load-bearing — don't change it without updating
   the servlet.
3. If there's no current winner, or this bid's max exceeds the current
   winner's max, this bidder becomes the winner. The new visible price is
   `LEAST(newMax, oldWinnerMax + increment)` — never higher than necessary to
   win, and never above the bidder's own max.
4. Otherwise, the current winner keeps the lead, but the visible price rises
   to `LEAST(winnerMax, thisMax + increment)`.

The procedure is wrapped in `START TRANSACTION` / `COMMIT` with an
`EXIT HANDLER FOR SQLEXCEPTION` that rolls back and re-signals. This matters:
before that fix, a bid that failed partway through the "new winner" branch
(e.g. a bad `buyerID`) could leave the *previous* winner's `isWinning` flag
cleared without ever installing a new winner — the auction ended up with no
winner flagged at all. `PlaceBidProcedureIT` has a permanent regression test
for this (`failedBidDoesNotCorruptPreviousWinnerState`).

## Automation: triggers and the scheduled event

- **`activate_auction`** (`BEFORE UPDATE` on `auction`) — flips a `pending`
  auction to `active` once its `startDateTime` has arrived.
- **`check_alerts_on_auction`** (`AFTER INSERT` on `auction`) — matches the new
  auction against saved `alert` rows and inserts a `notification` for anyone
  whose alert criteria match.
- **`close_auctions_event`** — a MySQL `EVENT` that runs every minute and calls
  **`close_expired_auctions()`**, which closes any `active` auction whose
  `closeDateTime` has passed, writes a `sales_report` row if the reserve was
  met, and notifies the winner and seller (or just the seller, if reserve
  wasn't met).

These three objects, plus `place_bid` and `close_expired_auctions`, must be
present for the app to work correctly. `buy_me_db.sql` is generated with
`mysqldump --routines --triggers --events --single-transaction` specifically
so a fresh import includes them — a plain `mysqldump` (the default, no flags)
silently omits all of this.

## Known architectural debt (intentional, not an oversight)

Two categories of cleanup were deliberately scoped out of the pass that added
`AuthFilter` and the DAO layer improvements above:

1. **~35 JSPs still do their own inline JDBC** instead of calling a DAO —
   everything under `admin/` and `rep/` except the pages already listed above,
   most of `auction/`, and most top-level pages. The pattern to repeat, if
   this gets picked back up, is the same one used for the 5 pages that were
   converted: identify the query, add or extend a DAO method if a matching one
   doesn't already exist, swap the JSP's inline block for the DAO call.
2. **`browse.jsp`** (899 lines, the largest page in the app) builds a richer
   filtered/sorted query (status, category, condition, price range, 5 sort
   orders) than `AuctionDAO.searchAuctions()` currently supports, and renders
   from a `List<Map<String,Object>>` rather than `Auction` objects in ~13
   places. Converting it cleanly would mean extending both the DAO method and
   the `Auction` model (it currently has no field for the "total bid events"
   metric this page shows separately from bid count), then rewriting the
   render loop — a bigger, riskier change than the other four DAO extractions
   in this pass, and one that really needs browser-based visual verification
   this pass didn't have available. Left as inline JDBC, same as the ~35 above.
3. **No shared header/footer.** All 46 JSPs independently repeat their own
   `<html><head><style>...` shell and navbar — there's no `<jsp:include>` or
   JSP fragment convention anywhere in the app. Extracting one is
   straightforward in principle but genuinely needs a person clicking through
   the rendered pages in a browser to catch any per-role navbar or styling
   difference that a blind text-level extraction would miss; this pass didn't
   have that available, so it's left as-is.
