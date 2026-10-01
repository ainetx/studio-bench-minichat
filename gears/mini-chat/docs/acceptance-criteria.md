# Acceptance Criteria: Mini Chat

Behavior the `mini-chat` gear MUST be implemented and tested exactly as specified in `PRD.md` / `DESIGN.md` / `docs/ADR/*.md` — each item here is both a requirement from the design and a fact the e2e test suite (`testing/e2e/suites/mini_chat/`) actually asserts, not merely a design intention. Each item is a single pass/fail fact — an exact status code, error reason, field name, numeric default, or ordering rule — not a restatement of the full behavior; see the referenced document section for the complete rationale and context.

This supersedes `E2E-SCENARIOS.md`: that file mapped requirements to test names and classes for engineers maintaining the test suite. This file drops the test-traceability columns and keeps only the requirement itself, so it reads as a checklist for whoever is implementing the gear, not a map of the test suite's internals.

**347 criteria across 20 categories.** Scope is limited to what the e2e suite actually covers — requirements that are unit-tested only, architectural/not independently testable, or explicitly out of P1 scope are not listed here (see DESIGN.md and the ADRs for those).

---

## 01 — Principles & Constraints

- [ ] **01-01** Tenant-Scoped Isolation
- [ ] **01-02** Owner-Only Content Access
- [ ] **01-06** Image on a Model Without Vision → 400 `invalid_argument` (`VISION_NOT_SUPPORTED`), no turn, provider not called
- [ ] **01-08** Context Window Budget: message over `max_input_tokens` → 400 `out_of_range` (`INPUT_TOO_LONG`); mandatory context (system prompt + message) over the budget `min(max_input_tokens, context_window - max_output_tokens_applied) - fixed_overhead_tokens` (minus tool surcharges; 2500 on the tiny model, not the uncapped 2572) → 400 `out_of_range` (`CONTEXT_BUDGET_EXCEEDED`)
- [ ] **01-10** No Buffering Constraint
- [ ] **01-11** Model Locked Per Chat
- [ ] **01-12** Quota Before Outbound
- [ ] **01-18** `max_input_tokens: 0` = No Separate Input Limit: no `INPUT_TOO_LONG`, budget `context_window - max_output_tokens_applied - fixed_overhead_tokens`

## 02 — Chat CRUD

- [ ] **02-01** Create Chat with Default Model → 201
- [ ] **02-02** Create Chat with Custom Model → 201
- [ ] **02-03** Create Chat with Title → 201
- [ ] **02-04** Create Chat with Unknown Model → 400 `invalid_argument` (`INVALID_MODEL`)
- [ ] **02-05** Get Chat → 200
- [ ] **02-06** Get Chat Not Found → 404 `not_found`
- [ ] **02-07** List Chats with Cursor Pagination
- [ ] **02-08** Update Chat Title → 200, `updated_at` bumped
- [ ] **02-09** Update Chat Not Found → 404 `not_found`
- [ ] **02-10** Delete Chat → 204, then GET/DELETE → 404, not listed
- [ ] **02-11** Delete Chat Not Found → 404 `not_found`
- [ ] **02-12** Update Title — Whitespace-Only → 400 `invalid_argument`
- [ ] **02-13** Update Title — 255 chars → 200, 256 → 400
- [ ] **02-14** Create Chat with Disabled Model → 400 `invalid_argument` (`INVALID_MODEL`)
- [ ] **02-15** Create Title — 255 chars → 201, 256 → 400
- [ ] **02-16** List Chats — Unknown `$filter` Field → 400 `invalid_argument` (`INVALID_FILTER`)
- [ ] **02-17** List Chats — Malformed Cursor → 400 (`INVALID_CURSOR`)
- [ ] **02-18** List Ordered by Activity (send moves chat to top)
- [ ] **02-19** Update Without Title (schema-invalid) → 422 `invalid_argument`
- [ ] **02-20** Update with Malformed JSON → 400 `invalid_argument`
- [ ] **02-21** Full Conversation Lifecycle (3 turns, history, `message_count`, turn status, total daily usage grows by the sum of the three turns' costs, replay charges nothing, delete)
- [ ] **02-22** Create Title — Whitespace-Only → 400 `invalid_argument`
- [ ] **02-23** Create with Schema-Invalid Body (`model: 123`) → 422 `invalid_argument`
- [ ] **02-24** Create with Malformed JSON → 400 `invalid_argument`
- [ ] **02-25** List Chats — Unknown `$orderby` Field → 400 `invalid_argument` (`INVALID_ORDERBY_FIELD`)
- [ ] **02-26** List Chats — Cursor Continued with Another or Without Its `$filter` → 400 `invalid_argument` (`FILTER_MISMATCH`); the cursor carries only the filter hash
- [ ] **02-27** List Chats — `limit=0` → 400 `invalid_argument` (`INVALID_LIMIT`)
- [ ] **02-28** List Chats — `cursor` with `$orderby` → 400 `invalid_argument` (`ORDER_WITH_CURSOR`)
- [ ] **02-29** Create Chat → 201 with `Location: /mini-chat/v1/chats/{id}` (the path the gear router sees, without the api-gateway `prefix_path`)
- [ ] **02-30** List Chats — `limit` Above 100 → Clamped to 100 (`page_info.limit` 100), not 400
- [ ] **02-31** List Chats — Invalid OData Options → 400 `invalid_argument` (`odata` resource, one violation on the option): duplicate `$select` (`INVALID_SELECT`), `$skip` (`UNSUPPORTED_QUERY_PARAM`), `$filter` over 8 KiB (`FILTER_TOO_LONG`), over 2000 nodes (`FILTER_TOO_COMPLEX`), `limit=abc` (`INVALID_QUERY_PARAMS` on `query`)
- [ ] **02-32** List Chats — Valid `$filter` on Each Field: `title eq`, `contains(title, ...)`, `id eq`, `updated_at ge` → exactly the matching chats, newest first
- [ ] **02-33** List Chats — `$orderby` on Each Field (`title` asc/desc, `updated_at asc`, `id` asc/desc) sorts the page by that field
- [ ] **02-34** List Chats — `page_info.prev_cursor`: absent on the first page, set on the next; following it returns the first page (with `next_cursor`, without `prev_cursor`)
- [ ] **02-35** List Chats — `$top` / `$skiptoken` Are Aliases of `limit` / `cursor` (same pages); both spellings of one option in a request → 400 `invalid_argument` (`odata` resource)
- [ ] **02-36** Chat Title Trimmed on Create and Update (leading and trailing whitespace)

## 03 — Messages API

- [ ] **03-01** List Messages — Cursor Pagination
- [ ] **03-02** OData `$select`: accepted and ignored (the page equals the one without it); an invalid value (duplicate field) → 400 `invalid_argument` (`INVALID_SELECT`)
- [ ] **03-03** OData `$orderby=created_at desc`: exactly the reversed default order (two turns)
- [ ] **03-04** OData `$filter=role eq 'assistant'`: exactly the answers of two turns, in order
- [ ] **03-05** Message request_id Always Non-Null
- [ ] **03-06** Attachments Array Always Present
- [ ] **03-07** `my_reaction` Present (required) on Every Message, null Without a Reaction
- [ ] **03-08** User + Assistant Messages Share request_id (every turn pair; each turn its own)
- [ ] **03-09** Unknown `$filter` Field → 400 `invalid_argument` (`INVALID_FILTER`)
- [ ] **03-10** Messages of Nonexistent Chat → 404 `not_found`
- [ ] **03-11** Chat `message_count`: 0 for a new chat, +2 per turn (two turns)
- [ ] **03-12** Messages Ordered Chronologically (two completed turns: content and request_id in order)
- [ ] **03-13** Unknown `$orderby` Field → 400 `invalid_argument` (`INVALID_ORDERBY_FIELD`)
- [ ] **03-14** Malformed Cursor → 400 `invalid_argument` (`INVALID_CURSOR`)
- [ ] **03-15** Cursor Continued with Another or Without Its `$filter` → 400 `invalid_argument` (`FILTER_MISMATCH`)
- [ ] **03-16** `limit=0` → 400 `invalid_argument` (`INVALID_LIMIT`)
- [ ] **03-17** `cursor` with `$orderby` → 400 `invalid_argument` (`ORDER_WITH_CURSOR`)
- [ ] **03-18** `limit` Above 100 → Clamped to 100 (`page_info.limit` 100), not 400
- [ ] **03-19** Unsupported `$` Query Option (`$skip`) → 400 `invalid_argument` (`UNSUPPORTED_QUERY_PARAM`)
- [ ] **03-20** `$filter` Longer Than 8 KiB → 400 `invalid_argument` (`FILTER_TOO_LONG`)
- [ ] **03-21** `$filter` Over 2000 Nodes (within 8 KiB) → 400 `invalid_argument` (`FILTER_TOO_COMPLEX`)
- [ ] **03-22** `limit=abc` → 400 `invalid_argument` (`INVALID_QUERY_PARAMS` on `query`)
- [ ] **03-23** `page_info.prev_cursor` Pages Back (limit 2 over three turns); `$top` / `$skiptoken` accepted as `limit` / `cursor`
- [ ] **03-24** Attachment Summaries on the User Message after a Send: `attachment_id`, `kind`, `filename`, `status`; an image also has `img_thumbnail` (the same as the attachment detail), a document none; the answer has none

## 04 — Streaming: Send Message

- [ ] **04-01** Send Message → 200 `Content-Type: text/event-stream` (also retry, edit and a replay)
- [ ] **04-02** Server Generates request_id if Omitted
- [ ] **04-03** Client request_id Echoed in stream_started
- [ ] **04-04** Attachment ID Not a UUID → 422 `invalid_argument`
- [ ] **04-05** Unknown Attachment ID → 400 `invalid_argument` (`invalid_attachment`), provider not called
- [ ] **04-06** Empty Content → 400 `invalid_argument` (`EMPTY_CONTENT`)
- [ ] **04-07** Missing Content (schema-invalid) → 422 `invalid_argument`
- [ ] **04-08** Chat Not Found → 404 `not_found` (JSON)
- [ ] **04-09** Messages Persisted After Stream: exactly the user message and the answer, in order, with the sent content, the `delta` text, the turn's request_id and an empty attachments array
- [ ] **04-10** Assistant Message Stores the Token Counts of `done`
- [ ] **04-11** Too Many Images per Message → 400 `out_of_range`
- [ ] **04-12** Attachment of Another Chat, of a Failed Upload, Deleted, Still Uploading (`pending`), Stored but Still Being Indexed (`uploaded`), Listed Twice, or More IDs than `max_documents_per_chat + max_images_per_message` → 400 `invalid_argument` (`invalid_attachment`), no turn, provider not called
- [ ] **04-13** Malformed JSON Body → 400 `invalid_argument` (JSON, not SSE)
- [ ] **04-14** Whitespace-Only Content → 400 `invalid_argument` (`EMPTY_CONTENT` on `content`: the content is trimmed), no turn
- [ ] **04-15** Provider SSE Events Without `event:` Lines Are Dispatched by `data.type`: a plain answer and a web search answer (tool events, citations) complete with `done`

## 05 — SSE Event Contract

- [ ] **05-01** stream_started: First Event with Fields (`request_id`, `message_id`)
- [ ] **05-02** stream_started: is_new_turn=true on Send
- [ ] **05-03** stream_started: is_new_turn=false on Replay
- [ ] **05-04** Delta Events: type=text, content=string
- [ ] **05-05** Tool Events: phase/name/details (web search: `web_search` `start` then `done`, `details` `{}` on both; code interpreter: `start`, then `done` with the logs output from `response.output_item.done`; file search: `file_search` `start` (`details` `{}`) then `done` (`details.files_searched`: the number of results in `response.file_search_call.completed`, 0 because OpenAI sends none there); exact values, offline)
- [ ] **05-06** Citations Event: items Array
- [ ] **05-07** File Citation (OpenAI shape: `file_id`, `filename`, `index`) → `attachment_id` and Filename, Empty `snippet`, No `span`, No Provider File ID; Unknown File Dropped
- [ ] **05-08** Done Event: Core Fields
- [ ] **05-09** Done Event: Usage Tokens (no internal token fields)
- [ ] **05-10** Done Event: quota_warnings Array
- [ ] **05-11** Done Event: Downgrade Fields
- [ ] **05-12** Done Event: message_id NOT in done
- [ ] **05-13** Error Event: Terminal with Code and the Provider Message (`response.failed` with `response.error`; flat SSE `error` event)
- [ ] **05-14** Error: Provider Details Sanitized
- [ ] **05-15** Ping Events only before the first content (ADR-0010): no content for about 8 s (two provider gaps of 4 s, each under the OAGW idle timeout of 8 s) with `sse_ping_interval_seconds` 5
- [ ] **05-16** Event Ordering Grammar: one `stream_started` first, then `ping`/`delta`/`tool`, one terminal `done` last; `citations` right before `done`; `tool` events relayed in the provider's order among the deltas (exact sequences for the mock web search answer, delta-tool-deltas, and the code interpreter answer, tool-deltas)
- [ ] **05-17** Server Closes After Terminal
- [ ] **05-19** stream_started `request_id` Resolves in the Turn Status API (`done`)

## 06 — Idempotency & Replay

- [ ] **06-01** Replay Completed Turn → 200 (same deltas; `done` rebuilt from the stored turn with the same `usage`, `effective_model`, `selected_model`, `quota_decision`); a replay of a downgraded turn keeps `quota_decision` `downgrade` and `downgrade_from` (`downgrade_reason` is not stored) and does not call the provider
- [ ] **06-02** Replay: is_new_turn=false, Same message_id
- [ ] **06-03** Replay: No LLM Call, No Quota, No Outbox
- [ ] **06-04** Multiple Replays Side-Effect-Free
- [ ] **06-05** Running Turn + Same request_id → 409 `aborted` (`request_id_conflict`, detail "request_id is already used by another turn in this chat")
- [ ] **06-06** Failed Turn + Same request_id → 409 `aborted` (`request_id_conflict`, same detail)
- [ ] **06-07** Cancelled Turn + Same request_id → 409 `aborted` (`request_id_conflict`, same detail)
- [ ] **06-08** Replay Priority Over Parallel Turn Check
- [ ] **06-09** Replay Does Not Modify Quota
- [ ] **06-10** request_id of a Turn Replaced by Retry → 409 `aborted` (`request_id_conflict`, same detail)
- [ ] **06-11** request_id of a Turn Removed by DELETE /turns → 409 `aborted` (`request_id_conflict`, same detail), no new turn
- [ ] **06-12** request_id of a Completed Turn in Another Chat of the Same User → a New Turn in This Chat (`is_new_turn` true, `done`), not a replay or a conflict: the key is `(chat_id, request_id)`
- [ ] **06-13** `request_id` Not a UUID → 422 `invalid_argument`, no turn, provider not called

## 07 — Parallel Turn Enforcement

- [ ] **07-02** Second Stream → 409 `aborted` (`turn_already_running`, detail "Another turn is running in this chat")
- [ ] **07-03** New Stream Succeeds After Previous Terminal
- [ ] **07-04** Send While a Retry or Edit Streams → 409 `aborted` (`turn_already_running`, detail "Another turn is running in this chat"); the mutation completes and is the only turn

## 08 — Turn Mutations

- [ ] **08-01** Retry Latest Terminal Turn
- [ ] **08-02** Retry Running Turn → 400 `failed_precondition` (`turn_state`/`STATE`)
- [ ] **08-03** Retry Non-Latest Turn → 409 `aborted` (`NOT_LATEST_TURN`)
- [ ] **08-04** Retry Generates New request_id
- [ ] **08-05** Edit: Replace Content + Regenerate
- [ ] **08-06** Edit Stream Has the Send Contract (`stream_started` with a new request_id, `ping`/`delta`, `done` with models and quota decision)
- [ ] **08-07** Delete Last Turn → 204
- [ ] **08-08** Delete Running Turn → 400 `failed_precondition` (`turn_state`/`STATE`)
- [ ] **08-09** Delete Non-Latest Turn → 409 `aborted` (`NOT_LATEST_TURN`)
- [ ] **08-10** Soft-Deleted Turn Not in Messages
- [ ] **08-11** Concurrent Retries: one 200, the other 409 `aborted` (`NOT_LATEST_TURN`: mutations are serialized on the SQLite rig; `GENERATION_IN_PROGRESS` needs two mutation transactions in flight and only its error mapping is unit-tested in gears/mini-chat/mini-chat/src/api/rest/error.rs)
- [ ] **08-12** Retry Failed or Cancelled Turn
- [ ] **08-13** Old Turn Marked with replaced_by_request_id
- [ ] **08-14** Edit with Empty Content → 400 `invalid_argument` (`EMPTY_CONTENT`)
- [ ] **08-15** Edit Non-Latest Turn → 409 `aborted` (`NOT_LATEST_TURN`)
- [ ] **08-16** GET Deleted Turn → 404 `not_found`
- [ ] **08-17** Second Delete of a Turn → 409 `aborted` (`NOT_LATEST_TURN`)
- [ ] **08-18** Deleted Turn Not Sent to Provider
- [ ] **08-19** Retry of Old Turn While Its Retry Streams → 409 `aborted` (`NOT_LATEST_TURN`)
- [ ] **08-20** Retry, Edit or Delete of an Unknown request_id → 404 `not_found`
- [ ] **08-21** Edit Running Turn → 400 `failed_precondition` (`turn_state`/`STATE`), the turn keeps streaming
- [ ] **08-22** Edit Without `content` → 422, Malformed JSON → 400 `invalid_argument`; the turn is kept
- [ ] **08-23** Edit Content over `max_input_tokens` → 400 `out_of_range` (`INPUT_TOO_LONG`), turn kept, provider not called
- [ ] **08-24** Edit Content over the Context Budget (tiny-context model) → 400 `out_of_range` (`CONTEXT_BUDGET_EXCEEDED`), provider not called; context assembly runs after the edit committed, so the old turn is replaced and the new turn is `error` with `context_length_exceeded`, no answer, no usage event, no reserve left (DESIGN §3.9)
- [ ] **08-25** Edit with Whitespace-Only Content → 400 `invalid_argument` (`EMPTY_CONTENT` on `content`), turn kept
- [ ] **08-26** Retry or Edit in a Chat Whose Model Left the Catalog (DB seed) → 400 `invalid_argument` (`INVALID_MODEL` on `model`, chat resource), turn kept, provider not called
- [ ] **08-27** Retry or Edit Copy the Replaced Message's Attachments Except Soft-Deleted Ones (DB seed of `deleted_at`); the new request carries the image as `input_image` and `file_search`
- [ ] **08-28** Retry or Edit Re-Run the Image Checks Before the Turn Is Replaced: image turn after the chat model is switched to one without vision (DB seed) → 400 `VISION_NOT_SUPPORTED`; a fifth image linked in the DB → 400 `out_of_range` `TOO_MANY_IMAGES`; turn kept, provider not called
- [ ] **08-29** Retry over the Context Budget: a 6000-byte question sent on gpt-5.2, then the chat switched to the tiny-context model (DB seed) → 400 `out_of_range` (`CONTEXT_BUDGET_EXCEEDED`), provider not called; the old turn is replaced, the new turn is `error` with `context_length_exceeded`, no answer, no usage event, no reserve left
- [ ] **08-30** Retry or Edit Sends the (New) Question Once, After the History Before the Turn, With and Without Earlier Turns (regression: the only live turn was sent twice when the snapshot boundary was missing)
- [ ] **08-31** Tool Quotas on Retry and Edit: at the daily `web_search` quota, a retry or edit of a turn that used web search (the flag is kept) → 429 `resource_exhausted` (`web_search`); at the daily `code_interpreter` quota, a retry or edit in a chat with a ready XLSX → 429 (`code_interpreter`); the old turn is kept, provider not called. Control: at the same quotas, a retry or edit of a turn without web search, or in a chat without an XLSX, runs

## 09 — Turn Lifecycle

- [ ] **09-01** Turn Is `running` Right After `stream_started` (GET turn while the stream is open), `done` After It
- [ ] **09-02** Preflight Rejection → JSON Error, No Turn Row
- [ ] **09-04** Quota Fields Persisted at Preflight (`reserve_tokens`, `reserved_credits_micro`, `max_output_tokens_applied`, `minimal_generation_floor_applied`: literal values while the turn runs, unchanged after completion)
- [ ] **09-05** Completed → assistant_message_id Set
- [ ] **09-06** Cancelled With Content → Partial Message
- [ ] **09-07** Cancelled Without Content → message_id NULL
- [ ] **09-08** Failed Turn → the stream ends with one SSE `error` (`provider_error`, the provider message), no `done`; turn `error` with `provider_error`, message_id NULL, no answer
- [ ] **09-09** Cancelled Message in GET /messages (starts with the deltas the client received, a prefix of the full answer)
- [ ] **09-11** Turn State Machine: `running` → `done` / `cancelled` / `error`
- [ ] **09-12** GET Unknown Turn → 404 `not_found`

## 10 — Attachments

- [ ] **10-01** Upload Attachment → 201 `ready`
- [ ] **10-02** GET Attachment — Status `ready`
- [ ] **10-03** DELETE Attachment → 204, GET → 404 `not_found` (attachment `resource_type`)
- [ ] **10-04** DELETE Referenced Attachment → 409 `already_exists` (`attachment_locked`)
- [ ] **10-05** Unsupported MIME → 400 `invalid_argument` (`UNSUPPORTED_CONTENT_TYPE`)
- [ ] **10-06** Oversize Image → 400 `out_of_range` (`FILE_TOO_LARGE`)
- [ ] **10-07** Oversize Document → 400 `out_of_range` (`FILE_TOO_LARGE`)
- [ ] **10-08** Document Within Limit → 201 + Ready
- [ ] **10-09** size_bytes Matches Actual
- [ ] **10-10** MIME Inference from Extension
- [ ] **10-11** Kind Routing: XLSX→code_interpreter, TXT→file_search
- [ ] **10-12** Image Upload: kind=image
- [ ] **10-13** Multi-Provider Upload: each chat's upload reaches its own provider's Files API (`/v1/files` OpenAI, `/openai/files` Azure)
- [ ] **10-15** img_thumbnail of a Ready Image: `content_type` `image/webp`, fitted into 128x128 keeping the aspect ratio (200x100 → 128x64), `data_base64` a WebP (RIFF/WEBP header); the image is sent as `input_image` with its provider file id
- [ ] **10-16** Provider Upload Failure → 503 `service_unavailable` (detail "Service temporarily unavailable") with `Retry-After: 10` (every provider error; the upload concurrency limit answers 5, 10-40); the attachment is `failed` with `error_code` `upload_failed`
- [ ] **10-17** Streaming Size Counter (chunked upload, no Content-Length) over the Limit → 400 `out_of_range` (`FILE_TOO_LARGE`), nothing sent to the provider; the attachment row, inserted before the body is read, is `failed` with `file_too_large`
- [ ] **10-18** Upload with Content-Length over the Limit → 400 `out_of_range` (`FILE_TOO_LARGE` on field `content_length`): the Content-Length pre-check rejects it before any attachment row is inserted and before the streaming counter reads the part; nothing sent to the provider
- [ ] **10-19** Chunked-Encoding Streaming Counter
- [ ] **10-20** Images Not Added to Vector Store
- [ ] **10-21** provider_file_id Never Exposed
- [ ] **10-22** Stream with Document → `file_search` Tool in the Provider Request
- [ ] **10-23** Mixed XLSX + TXT → Both Tools
- [ ] **10-24** Image + Document Combined: one request with `input_image` (the image's provider file id) in the user message and `file_search` on the chat's vector store; the model uses both (online)
- [ ] **10-25** GET Nonexistent Attachment → 404 `not_found` (attachment `resource_type`)
- [ ] **10-26** Documents per Chat Exceeded → 429 `resource_exhausted` (`document_limit`)
- [ ] **10-27** Storage per Chat Exceeded → 429 `resource_exhausted` (`storage_limit`): documents 1 KiB under the 100 MB chat limit, each within the per-file limit; a 100-byte upload fits, a 2 KiB upload is rejected, provider not called
- [ ] **10-29** Deleted Document: its citations are dropped
- [ ] **10-30** XLSX Upload Accepted and Ready
- [ ] **10-31** Code Interpreter Tool Events in Stream (`start`, `done`, after `stream_started` and before the deltas that follow the call)
- [ ] **10-32** code_interpreter Tool with container.file_ids (the XLSX provider file) and `include: ["code_interpreter_call.outputs"]` in Provider Request (no `include` without code_interpreter: TestXlsxPurposeRouting::test_txt_triggers_file_search_not_code_interpreter)
- [ ] **10-33** Code Interpreter Real Answer
- [ ] **10-34** Image Sent to the Model as `input_image`; Recognized by the Model
- [ ] **10-35** Per-Provider Send with Attachment; Medium File Pipeline (~500 KB: 201 `ready` with its exact size, the provider file added to the chat's vector store, `file_search` on it in the next request)
- [ ] **10-36** DELETE Unknown Attachment → 404 `not_found` (attachment `resource_type`)
- [ ] **10-37** XLSX Upload While Code Interpreter Is Unavailable (model without it) → 400 `invalid_argument`, nothing stored
- [ ] **10-38** Send Message Referencing Two Ready Documents → 200, `done`
- [ ] **10-39** Repeated DELETE of an Attachment → 204 (idempotent), then GET → 404
- [ ] **10-40** Upload While All `max_concurrent_uploads` (10) Permits Are Taken → 503 `service_unavailable`, `Retry-After: 5`, nothing stored; the held uploads then complete `ready`
- [ ] **10-41** Upload to an Unknown Chat → 404 `not_found` (chat `resource_type`)
- [ ] **10-42** Malformed Upload Request → 400 `invalid_argument` (attachment `resource_type`): multipart without a boundary (`BOUNDARY_REQUIRED`), unparsable multipart body (`MULTIPART_ERROR`), no `file` field (`MISSING_FILE`), `file` part without a Content-Type (`MISSING_CONTENT_TYPE`); nothing stored, provider not called
- [ ] **10-43** Provider-Native file_search Counted: `file_search` tool events (`details` as in 05-05), `chat_turns.file_search_completed_count` 1, usage event `file_search_calls` 1
- [ ] **10-44** More Than `code_interpreter_max_calls_per_message` (10) Code Interpreter Calls in One Answer → tool events of the 10 allowed calls, SSE `error` `code_interpreter_calls_exceeded`, turn `error` with that code (mock only)
- [ ] **10-47** Upload to a Chat Whose Model Left the Catalog (DB seed) → 400 `invalid_argument` (chat `resource_type`, field `model`, `INVALID_MODEL`), nothing stored, provider not called; other model-resolution failures are returned as is, no fallback storage provider
- [ ] **10-48** Ready Document in a Chat on a Model Without `tool_support.file_search` → No file_search Tool in the Provider Request
- [ ] **10-49** Upload Filename: a part without `filename=` is stored as `upload`; a name over 255 characters is cut to 255 keeping the extension
- [ ] **10-50** `application/octet-stream` with an Unknown Extension → 400 `invalid_argument` (`UNSUPPORTED_CONTENT_TYPE` on `content_type`), nothing stored, provider not called
- [ ] **10-51** Upload When the Chat's Vector Store Belongs to Another Storage Backend (DB seed: an Azure chat's store, then `chats.model` switched to an OpenAI model) → 409 `already_exists` (chat resource, `resource_name` `provider_mismatch`, detail "chat vector store belongs to another provider"); attachment `failed` (`vector_store_failed`), store kept, the file just stored at the provider deleted
- [ ] **10-52** Document Ready Only After Indexing: the vector store answers `in_progress` twice, then `completed` → 201 `ready` after two status reads of the vector store file (`GET /vector_stores/{id}/files/{file_id}`, the route registered for it in OAGW); the upload form's `purpose` is `assistants` (images: not asserted, issue #5022)
- [ ] **10-53** Indexing `failed` (on the add or after a poll) or `cancelled`, with `last_error` → 503 `service_unavailable` (detail "Service temporarily unavailable", `Retry-After: 10`, the error code not in the body); the attachment is `failed` with `indexing_failed`; the stored provider file is deleted. Indexing still running at the 25 s deadline is 10-59; a transient status read error is unit-tested only
- [ ] **10-54** Vector Store Creation Fails at the Provider → 503 `service_unavailable` (same detail, `Retry-After: 10`, the error code not in the body); the attachment is `failed` with `vector_store_failed`, no store recorded, the stored provider file deleted
- [ ] **10-55** Request with a Content-Length over the api-gateway `body_limit_bytes` (64 000 000) → 413 from the gateway, answered from the header (the test sends only the start of the body): `application/problem+json`, but not a canonical Problem (`type` `about:blank`, title and detail "Payload Too Large"), no attachment row, nothing sent to the provider
- [ ] **10-56** Attachment `uploaded` While the Vector Store Indexes It: GET reports `uploaded` during the status polls; it cannot be sent (04-12); once indexing completes the upload returns `ready`
- [ ] **10-57** Upload Reaper (slow, about 70 s): in a chat with `max_documents_per_chat` - 1 documents, the client drops the upload while the vector store is still indexing (indexing held, client read timeout 3 s) → the server stops polling (after at least one status read) and the row stays `uploaded` and counts against the limit (one more upload → 429 `document_limit`); once not updated for `stale_after_secs` (60 s in config/base.yaml, the minimum) GET reports `failed` with `error_code` `upload_abandoned`, the provider file is deleted (so gone from the chat's vector store) and `cleanup_status` ends `done`; the failed row no longer counts (a new document upload is `ready`). The api-gateway 30 s timeout is not the trigger in the rig: the upload's own indexing deadline (25 s) fails it first with `indexing_failed` (10-53). A stale `pending` row without a provider file is failed with no cleanup, and a row updated within the window is left alone (a live upload never exceeds 25 s, 10-56): unit tests only
- [ ] **10-58** CSV Upload (`rag.allow_csv_upload`, on by default) → 201 `ready`, stored and returned as `text/plain`, kind `document`; the switch off (CSV rejected) is unit-tested only: the rig runs with the default
- [ ] **10-59** Indexing Past the Request Deadline (slow, about 27 s): the vector store stays `in_progress` past the 25 s upload deadline → 201 with `status: uploaded`; a send with it is rejected (400 `invalid_attachment`); once indexing completes the background wait sets `ready`. The background failure and the 10-minute limit are unit-tested (`test_background_indexing_failure_marks_attachment_failed`, `test_upload_returns_uploaded_and_background_marks_ready` in gears/mini-chat/mini-chat/src/domain/service/attachment_service_test.rs)

## 11 — Models API

- [ ] **11-01** List Models
- [ ] **11-02** Catalog Models Listed (exactly the enabled `model_catalog` entries of config/base.yaml)
- [ ] **11-03** Model Has Required Fields; `multiplier_display` Is the Catalog Value of config/base.yaml
- [ ] **11-04** Get Existing Model → 200 (the requested `model_id`)
- [ ] **11-05** Get Nonexistent Model → 404 `not_found` (`resource_type` model, `resource_name` the model id)
- [ ] **11-06** Internal Fields Not Exposed
- [ ] **11-07** Disabled Model Not Listed
- [ ] **11-08** Extended Response Fields
- [ ] **11-09** Get Disabled Model → 404

## 12 — Reactions API

- [ ] **12-01** Set Reaction (like) → 200
- [ ] **12-02** Reaction Upsert Idempotent
- [ ] **12-03** Reaction on User Message (PUT and DELETE) → 400 `failed_precondition` (`reaction_target`/`STATE`)
- [ ] **12-04** Remove Reaction → 204
- [ ] **12-05** Remove Reaction Idempotent → 204 (a second DELETE after the removal; a DELETE with no reaction set), nothing stored
- [ ] **12-06** Switch Reaction like → dislike
- [ ] **12-07** Reaction on Nonexistent Message → 404 `not_found` (PUT and DELETE; `resource_type` message, `resource_name` the message id)
- [ ] **12-08** Reaction Other Than like/dislike → 400 `invalid_argument`, nothing stored
- [ ] **12-09** Reaction Without `reaction` → 422, Malformed JSON → 400 `invalid_argument`; nothing stored
- [ ] **12-10** Reaction on the Answer of a Deleted Turn (PUT and DELETE) → 404 `not_found` (message resource), nothing stored

## 13 — Quota Status API

- [ ] **13-01** Quota Status Endpoint Structure (`warning_threshold_pct` = configured 80)
- [ ] **13-02** Each Tier Has Periods
- [ ] **13-03** remaining_percentage in [0, 100]
- [ ] **13-04** next_reset Is Future
- [ ] **13-05** Credits Increase by Each Turn's Cost (two turns)
- [ ] **13-06** remaining_credits_micro Decreases After Send
- [ ] **13-07** SSE quota_warnings Equal REST
- [ ] **13-08** Warning Fires at Threshold Boundary
- [ ] **13-09** Exhausted Flag at Zero
- [ ] **13-10** Usage Accounted per User (owner charged the turn's cost, other user unchanged)
- [ ] **13-11** SSE `quota_warnings[].next_reset` Only on an Entry with `warning` or `exhausted`, then Equal to the Status Endpoint's

## 14 — Quota Enforcement

- [ ] **14-01** Preflight Reserve Persisted (while the turn runs; unchanged after completion)
- [ ] **14-02** Tier Downgrade: Premium Exhausted → Standard
- [ ] **14-03** Bucket Model: a premium turn charges `total` and `tier:premium`, a standard turn `total` only, each by the `done` usage times the model multipliers
- [ ] **14-04** Daily + Monthly Periods Both Checked
- [ ] **14-05** All Tiers Exhausted → 429 `resource_exhausted`, one violation: subject `tokens`, description `quota_exceeded`
- [ ] **14-06** Reserve Before Provider Call: the reserve is persisted while the provider streams; a reserve that does not fit is rejected before the provider is called
- [ ] **14-07** Credits Formula: tokens × per-token multiplier, exact integer credits_micro (computed from the `done` usage)
- [ ] **14-08** max_output_tokens Hard Cap (`max_output_tokens_applied` 8192 on the turn, `max_output_tokens` 8192 in the provider request)
- [ ] **14-09** policy_version_applied Persisted (1, the version of the static model policy plugin)
- [ ] **14-11** No Stuck Reserves After Completion
- [ ] **14-12** Web Search Surcharge in Reserve: exactly `web_search_surcharge_tokens` (500) more reserve tokens and 500 × 3 more credits for the same first message (literal values)
- [ ] **14-15** Retry While Exhausted → 429, Old Turn Kept
- [ ] **14-16** Disabled Chat Model → Downgrade (`model_disabled`)
- [ ] **14-17** Web Search Daily Quota → 429 `resource_exhausted` (`web_search`) only for web-search requests; one call below the quota the turn runs with the `web_search` tool and its search is counted (the daily row reaches the quota)
- [ ] **14-18** Web Search Turn Credits and Tokens
- [ ] **14-19** Code Interpreter Turn Credits (from the usage the provider reported) and `code_interpreter_calls`; the same `CODEINTERP:` prompt in a chat without an XLSX offers no code_interpreter tool and counts no call
- [ ] **14-20** Code Interpreter Daily Quota → 429
- [ ] **14-23** Edit While Exhausted → 429 `resource_exhausted` (`tokens`), Old Turn Kept, Provider Not Called
- [ ] **14-24** Each Cascade Candidate Checked with Its Own Reserve: 60 000 credits_micro left in `total` — below the premium reserve (8192 output tokens × 15), above the standard one — → downgrade to gpt-5.2 (`premium_quota_exhausted`), not 429
- [ ] **14-26** A Downgraded Turn Is Sent to the Effective Model's Provider: a premium chat (azure-gpt-4.1, Azure) downgraded to gpt-5.2 sends the request to OpenAI `/v1/responses`, not to Azure

## 15 — Settlement & Finalization

- [ ] **15-03** Completed: Actual Settlement
- [ ] **15-06** Cancelled After Content, No Provider Usage → Estimated Charge (`aborted`, literal credits), Reserve Released
- [ ] **15-07** Cancelled Before Content → Estimated Charge (`aborted`, literal credits), Reserve Released
- [ ] **15-08** Provider Failure → Estimated Charge (`failed`, literal credits), Reserve Released
- [ ] **15-11** Outbox Dedupe Key Format
- [ ] **15-13** One Usage Outbox Message Per Terminal Turn (completed, cancelled, failed)
- [ ] **15-14** Completed Turn Releases Reserve
- [ ] **15-15** Settlement on the Provider's Token Counts: one `actual` usage event whose credits are the provider-reported usage (offline: the mock's `response.usage`, which must also be the `done` usage; online: `done`) times the model multipliers (both providers)
- [ ] **15-17** Provider `response.incomplete` → `done`, Turn `completed` with No Error Code, Truncated Text Persisted, Actual Settlement on `response.usage`
- [ ] **15-18** Usage Event `requester_type`: `user` (with `user_id`) for a turn, `system` (no `user_id`, no `turn_id`) for the thread summary
- [ ] **15-19** Cached and Reasoning Tokens: stored on the message and sent in the usage event, not in `done`; credits use only total input and output tokens
- [ ] **15-20** `response.failed` with `response.usage` → SSE `error` `provider_error`, turn failed, settled on that usage (`failed`, `actual`, literal credits); with `usage: null` the estimate is charged

## 16 — Context Assembly

- [ ] **16-01** System Prompt Delivered (`instructions` equal to the catalog prompt when no tool guard applies)
- [ ] **16-02** System Prompt Across Models
- [ ] **16-03** Recent Messages: Oldest First, Up to `recent_messages_limit` (10)
- [ ] **16-04** Deleted Turns Excluded
- [ ] **16-05** Thread Summary Replaces Older Messages; a turn that does not fit next to the summary is dropped whole (question and answer), never an answer without its question
- [ ] **16-06** Only Messages After Summary Boundary; truncation drops whole turns
- [ ] **16-07** Model Recall from Earlier Turns
- [ ] **16-08** web_search Tool with search_context_size (default `low`)
- [ ] **16-09** file_search Tool with max_num_results
- [ ] **16-10** web_search Disabled → No Tool
- [ ] **16-11** max_tool_calls in Provider Request
- [ ] **16-12** Cancelled Partial Message in Context
- [ ] **16-13** Empty Cancelled Turn → No Message
- [ ] **16-14** Tool Guard Instructions Appended
- [ ] **16-15** Missing System Prompt → None
- [ ] **16-16** Provider Identity: `user` is the hyphen-less tenant and user UUIDs concatenated (64 characters, the OpenAI/Azure limit); `metadata` has tenant, user, chat, `request_type` (`chat` for a turn, `summary` for the thread summary, which runs as the platform default subject: checked in a chat of user B, because the default subject id is user A's id in this rig) and the tool `feature`
- [ ] **16-17** `metadata.feature` of Attachment Tools: `file_search` (document), `code_interpreter` (XLSX), `file_search+code_interpreter` (both)
- [ ] **16-18** Provider Endpoints: OpenAI `/v1/files`, `/v1/vector_stores`, `/v1/vector_stores/{id}/files`, `/v1/responses` without a query; Azure `/openai/files`, `/openai/vector_stores`, `/openai/vector_stores/{id}/files` with `api-version=2025-03-01-preview` and the Responses `api_path` `/openai/v1/responses` (the v1 API) without one

## 17 — Error Mapping & Sanitization

- [ ] **17-01** Pre-Stream Errors → Problem JSON
- [ ] **17-02** Post-Stream → SSE event: error
- [ ] **17-03** Provider Timeout → provider_timeout
- [ ] **17-04** Provider Unavailable (HTTP 503) → `provider_error` with the provider's sanitized `error.message`
- [ ] **17-05** Provider 429 → `rate_limited`, message `Rate limited by provider` without `Retry-After`; with `Retry-After: 7` (passed through by OAGW) `Rate limited by provider; retry in 7s`: the delay reaches the client only in the message; turn `error` with `rate_limited`
- [ ] **17-06** Error Sanitization: No Provider IDs; each id is replaced by `[provider_id]` and the rest of the message is kept (`response.failed` and HTTP 500)
- [ ] **17-07** 404 Masking: Foreign Resource → 404 `not_found` with the same body (`type`, `detail`, `context.resource_type`, `instance`) as the owner's 404 for a chat id that does not exist, once the chat id is masked
- [ ] **17-08** Schema-Invalid Body → 422 `invalid_argument` (one violation on `body`, reason `invalid_json_body`)
- [ ] **17-09** Malformed JSON → 400 `invalid_argument` (`json_syntax_error`)
- [ ] **17-10** Provider HTTP 504 → `provider_error` (not `provider_timeout`) with the provider's sanitized `error.message`
- [ ] **17-11** Provider `function_call` Output Item While No Function Tool Is Offered (knowledge search not configured) → SSE `error` `unexpected_tool_use`, turn `error` with that code
- [ ] **17-12** Path Parameter Not a UUID (chat id, turn request_id, attachment id, message id of the reaction path on PUT and DELETE) → 400 `invalid_argument`, `field_violations[].reason = invalid_path_params`
- [ ] **17-13** Send to a Chat Whose Model Left the Catalog (DB seed) → 400 `invalid_argument` (`INVALID_MODEL`), no turn, provider not called
- [ ] **17-14** 404 `resource_type` Names the Missing Resource (turn, message, model; `resource_name` its id)
- [ ] **17-15** Provider Stream Ends Without a Terminal Event → SSE `error` `provider_error` (`stream ended without terminal event`: an invalid response; `stream_interrupted` is only for a provider task that ends without one), turn `error`, no answer stored, estimated settlement (`failed`)
- [ ] **17-16** `function_call` With Arguments That Are Not JSON → SSE `error` `provider_error` (`function_call arguments were not valid JSON: ...`), checked before the tool name, turn `error`
- [ ] **17-17** JSON Body Without a JSON `Content-Type` (none, or `text/plain`) → 415 `invalid_argument`, one violation on `body` (`missing_json_content_type`), no turn: create chat, update chat, send, edit, reaction PUT
- [ ] **17-18** Provider `response.completed` Without `usage` (the real API always sends it) → SSE `error` `provider_error` (``SSE parse error: failed to parse response completed: missing field `usage` ...``), no `done` with zero usage; the turn fails and is settled on the estimate

## 18 — Web Search

- [ ] **18-01** Web Search Tool Events (`web_search` `start` then `done`, after `stream_started`, between the deltas of the two answer messages, before `done`)
- [ ] **18-02** Web Search Citations (the `url_citation` range is sliced from the `output_text` part that carries it, in characters)
- [ ] **18-03** Citations Right Before Done
- [ ] **18-04** No web_search Tool Without the Flag: a `SEARCH:` prompt without `web_search` sends no `tools`
- [ ] **18-05** Works on Standard Model
- [ ] **18-06** Turn Done After Web Search
- [ ] **18-07** Messages Persisted After Web Search: exactly the user message and the answer, in order, with the sent content, the `delta` text and the turn's request_id
- [ ] **18-08** Credits Tracked for Web Search Turns
- [ ] **18-10** Web Search Call Limits: daily quota; `max_tool_calls` sent to the provider; more than `web_search_max_calls_per_message` (2) in one answer → SSE `error` `web_search_calls_exceeded` (mock only)
- [ ] **18-11** Meaningful Answer
- [ ] **18-12** `web_search_calls` of the Daily `total` Usage Row Grows by the Completed Searches of a Turn
- [ ] **18-13** Web Search Requested on a Model Without `tool_support.web_search` (gpt-5-nano): no tool, no guard, feature `none`, the daily web_search quota not checked (allowed at the quota), requested flag stored on the turn, no web search counted

## 19 — Cleanup & Recovery

- [ ] **19-01** Chat Deletion → Background Cleanup
- [ ] **19-02** Chat Deletion Cleans Up the Attachment (`cleanup_status` → `done`, no retries) with one DELETE of its own provider file, which the mock then no longer holds
- [ ] **19-03** Provider 404 on Delete → Success
- [ ] **19-04** Vector Store Deleted After Attachments
- [ ] **19-05** Attachment Cleanup of a Chat with 3 Attachments (each → `done` after one DELETE of its own provider file)
- [ ] **19-09** Thread Summary Trigger (no summary task enqueued after a turn below the threshold, while that turn's usage event from the same transaction is; exactly one at the turn that reaches it, targeting the previous turn's answer: the triggering turn is not summarized)
- [ ] **19-10** Thread Summary Worker (summary model, stored summary and frontier, messages marked compressed; `token_estimate` is the summary response's output tokens without its reasoning tokens)
- [ ] **19-11** Retry of the Turn That Triggered the Summary → the Summary Does Not Cover It and Is Kept; the Request Has the Summary and the Original Question, Not the Replaced Answer
- [ ] **19-12** Second Chat Delete → 404, Single Cleanup Event
- [ ] **19-13** Empty Chat Deletion Still Enqueues Cleanup
- [ ] **19-16** Chat Deletion Does Not Cancel a Running Turn: it completes and is billed (ADR-0009)
- [ ] **19-17** Provider 403 on Every File Delete → the attachment cleanup is retried `max_attempts` times and ends in `failed`
- [ ] **19-18** Provider 500 on Every Vector Store Delete → the chat cleanup message is dead-lettered after `max_attempts` deliveries, not retried again (the processor offset is past it); the `chat_vector_stores` row stays
- [ ] **19-19** Attachment Deletion Enqueues Cleanup Event (with the provider file id); the cleanup deletes that file once and ends `done`
- [ ] **19-20** Mutation of a Turn the Summary Covers (after DELETE of the later turn) Drops the Summary in the Mutation Transaction: retry, edit or delete; a retry or edit is sent without the summary; the covered messages are uncompressed, so a retry of the second of three turns carries the first turn as history
- [ ] **19-21** Summary Request Fails at the Provider: retried, and the next request stores the summary; failing on all `max_attempts` (3) deliveries → the task is dead-lettered with the processor offset past it (never delivered again), no summary, no message compressed, the next turn sent without a summary
- [ ] **19-23** Summary Request Answered 400 `context_length_exceeded` → sent again without the oldest messages (six to summarize: two dropped), and that summary is stored with the same frontier

## 20 — Authorization

- [ ] **20-03** Foreign Resource → 404 `not_found`, Provider Not Called
- [ ] **20-04** Chat List Scoped to the Caller: another user's chat is not listed
- [ ] **20-05** Missing Token → 401 `unauthenticated` (`MISSING_BEARER`), `WWW-Authenticate: Bearer realm="api"`
- [ ] **20-06** Unknown Token → 401 `unauthenticated` (`AUTHN_FAILED`), `WWW-Authenticate: Bearer error="invalid_token"`
- [ ] **20-07** Foreign Mutations Leave Owner Data Unchanged (chat, messages, turn, attachment, no reaction)
- [ ] **20-10** Own Turn, Message and Attachment Ids Addressed Through Another Chat of the Same User → 404 `not_found` (GET/retry/edit/delete turn, GET/DELETE attachment, PUT/DELETE reaction); nothing changes
- [ ] **20-11** Retry, Edit or Delete of a Turn Another User Started (DB seed of `chat_turns.requester_user_id`; shared chats are not reachable in P1) → 403 `permission_denied` (`AUTHZ_DENIED`), nothing changed, provider not called
