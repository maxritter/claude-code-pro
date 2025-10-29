# Note-Taking MVP Application Design

**Date:** 2025-10-29
**Status:** Approved
**Purpose:** Simple CRUD note-taking application to help users remember important information

## Overview

A minimal viable product (MVP) for a note-taking application with full-stack implementation including frontend (Next.js), backend (FastAPI), database (PostgreSQL), and cloud infrastructure (AWS CDK). The application solves the problem of users forgetting important information by providing a simple interface to create, read, update, and delete notes.

## Architecture

### High-Level Structure

Three-tier architecture with clear separation of concerns:

- **Frontend (src/frontend)**: Next.js 14+ application with App Router
- **Backend (src/backend)**: FastAPI Python application
- **Infrastructure (src/infra)**: AWS CDK TypeScript for IaC

### Technology Stack

**Frontend:**
- Next.js 14+ (App Router)
- React 18+ with built-in hooks (useState)
- Plain CSS (no frameworks)
- Native fetch API for HTTP requests

**Backend:**
- FastAPI (Python)
- Pydantic for data validation
- SQLModel for database ORM
- Uvicorn ASGI server
- Async database operations

**Database:**
- PostgreSQL 14+
- Local: Port 5433 (postgres/postgres/postgres)
- Production: Aurora Serverless v2

**Infrastructure:**
- AWS CDK v2 (TypeScript)
- ECS Fargate (backend container)
- ECR (container registry)
- Aurora Serverless v2 (database)
- cdk-nextjs construct (frontend deployment)
- CloudFront + S3 (frontend hosting)

**Testing:**
- Playwright MCP (E2E testing)
- PostgreSQL MCP (database verification)
- Newman (API testing)
- curl (manual API testing)

## Data Model

### Note Entity

```python
class Note(SQLModel, table=True):
    __tablename__ = "notes"

    id: UUID (primary key, auto-generated)
    title: str (max 200 chars, required)
    content: str (text, required, unlimited length)
    created_at: datetime (auto-generated)
    updated_at: datetime (auto-updated)
```

### Database Schema

```sql
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notes_created_at ON notes(created_at DESC);
```

### Constraints

- `id`: Unique identifier, auto-generated UUID
- `title`: Required, max 200 characters
- `content`: Required, no length limit
- `created_at`: Auto-set on creation, indexed for sorting
- `updated_at`: Auto-updated on modification

## Backend API Design

### Endpoints

**Base URL:** `/api/notes`

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/notes` | List all notes | - | Array of Note objects |
| GET | `/api/notes/{id}` | Get single note | - | Single Note object |
| POST | `/api/notes` | Create note | `{title, content}` | Created Note (201) |
| PUT | `/api/notes/{id}` | Update note | `{title, content}` | Updated Note (200) |
| DELETE | `/api/notes/{id}` | Delete note | - | Success message (200) |

### Request/Response Format

**Create/Update Request:**
```json
{
  "title": "string (max 200 chars)",
  "content": "string (unlimited)"
}
```

**Note Response:**
```json
{
  "id": "uuid",
  "title": "string",
  "content": "string",
  "created_at": "ISO 8601 timestamp",
  "updated_at": "ISO 8601 timestamp"
}
```

### HTTP Status Codes

- `200 OK`: Successful GET, PUT, DELETE
- `201 Created`: Successful POST
- `404 Not Found`: Note ID doesn't exist
- `422 Unprocessable Entity`: Validation errors
- `500 Internal Server Error`: Database or server errors

### Error Handling

**Validation Errors (422):**
```json
{
  "detail": [
    {
      "loc": ["body", "title"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

**Not Found (404):**
```json
{
  "detail": "Note not found"
}
```

**Server Error (500):**
```json
{
  "detail": "Internal server error"
}
```

### CORS Configuration

- **Local Development:** Allow `http://localhost:3000`
- **Production:** Allow CloudFront distribution domain only

### Architecture Pattern

**Simple Routes Pattern:**
- Direct FastAPI route handlers in main.py
- Inline database queries using SQLModel
- Minimal files for MVP speed
- All business logic in route functions

### Health Check

- Endpoint: `GET /health`
- Purpose: ECS health checks and monitoring
- Response: `{"status": "healthy"}`

## Frontend Implementation

### Page Structure

**Single Page Application:**
- Main route: `/` (app/page.tsx)
- All CRUD operations on one page
- No routing or navigation needed

### Components

**NoteCard Component:**
```typescript
// Displays individual note with actions
- Props: note (Note object), onEdit, onDelete
- Shows: title, content, timestamps, Edit/Delete buttons
- Toggles to edit mode when Edit clicked
```

**NoteForm Component:**
```typescript
// Reusable form for create/edit
- Props: initialNote?, onSubmit, onCancel
- Controlled inputs for title and content
- Validation: title required, max 200 chars
```

**NoteList Component:**
```typescript
// Container for all notes
- Renders array of NoteCard components
- Handles empty state ("No notes yet")
```

### User Interactions

**Create Flow:**
1. User clicks "New Note" button
2. Form appears (modal or inline)
3. User enters title and content
4. Submit → POST /api/notes
5. New note appears in list

**Read Flow:**
1. Page loads → GET /api/notes
2. Notes displayed as cards sorted by created_at DESC
3. Full title and content visible in each card

**Update Flow:**
1. User clicks "Edit" on note card
2. Card transforms to edit form (inline)
3. User modifies title/content
4. Submit → PUT /api/notes/{id}
5. Card updates with new content

**Delete Flow:**
1. User clicks "Delete" on note card
2. Simple confirmation prompt
3. Confirm → DELETE /api/notes/{id}
4. Card removed from list

### State Management

**React useState:**
```typescript
const [notes, setNotes] = useState<Note[]>([]);
const [isCreating, setIsCreating] = useState(false);
const [editingId, setEditingId] = useState<string | null>(null);
```

**Optimistic Updates:**
- Update UI immediately on user action
- Rollback if API call fails
- Show error toast on failure

### Styling Approach

**Plain CSS:**
- Global styles in `global.css`
- Component-specific in CSS modules
- No frameworks (no Tailwind, Material UI, Bootstrap)

**Layout:**
- Responsive grid layout
- Mobile: 1 column
- Tablet: 2 columns
- Desktop: 3 columns

**Card Style:**
- Simple border and shadow
- Padding for readability
- Hover effects on buttons
- Clear visual hierarchy (title larger than content)

**Form Style:**
- Full-width inputs
- Clear labels
- Primary/secondary button styles
- Validation error messages in red

### API Integration

**Fetch Configuration:**
```typescript
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// Example: Create note
const response = await fetch(`${API_BASE}/api/notes`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ title, content })
});
```

**Error Handling:**
- Network errors: Show "Connection failed" message
- 404 errors: Show "Note not found"
- 422 errors: Display field-specific validation errors
- 500 errors: Show generic "Something went wrong"

## Infrastructure & Deployment

### Local Development Setup

**Prerequisites:**
- PostgreSQL running on port 5433 (postgres/postgres/postgres)
- Node.js 18+ for frontend
- Python 3.11+ with uv for backend
- Docker for containerization

**Running Locally:**
```bash
# Terminal 1: Backend
cd src/backend
uv run uvicorn main:app --reload --port 8000

# Terminal 2: Frontend
cd src/frontend
npm run dev

# Terminal 3: Database already running on 5433
```

**Environment Variables:**

Backend (.env):
```
DATABASE_URL=postgresql://postgres:postgres@localhost:5433/postgres
```

Frontend (.env.local):
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### Local Testing Strategy

**Phase 1: Manual Testing (curl)**
```bash
# Create note
curl -X POST http://localhost:8000/api/notes \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Test content"}'

# List notes
curl http://localhost:8000/api/notes

# Update note
curl -X PUT http://localhost:8000/api/notes/{id} \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated","content":"Updated content"}'

# Delete note
curl -X DELETE http://localhost:8000/api/notes/{id}
```

**Phase 2: Newman API Testing**
- Create Postman collection for all CRUD operations
- Export collection JSON
- Run via Newman CLI: `newman run collection.json`
- Verify all status codes and response schemas

**Phase 3: Playwright E2E Testing**
- Use Playwright MCP to automate browser testing
- Test complete user flows (create → read → update → delete)
- Verify UI updates correctly

**Phase 4: Database Verification**
- Use PostgreSQL MCP to query database directly
- Verify data integrity after operations
- Check timestamps are set correctly

### AWS Infrastructure (CDK)

**Project Structure:**
```
src/infra/
├── bin/
│   └── app.ts              # CDK app entry point
├── lib/
│   ├── backend-stack.ts    # ECS + ECR
│   ├── database-stack.ts   # Aurora Serverless v2
│   ├── frontend-stack.ts   # Next.js construct
│   └── network-stack.ts    # VPC + Security Groups
├── cdk.json
└── package.json
```

**Backend Stack (ECS Fargate):**
```typescript
new ApplicationLoadBalancedFargateService(this, 'Backend', {
  cluster,
  cpu: 256,
  memoryLimitMiB: 512,
  desiredCount: 1,
  taskImageOptions: {
    image: ContainerImage.fromEcrRepository(repository),
    containerPort: 8000,
    environment: {
      DATABASE_URL: /* from Secrets Manager */
    }
  },
  healthCheck: {
    path: '/health',
    interval: Duration.seconds(30)
  }
});
```

**Database Stack (Aurora Serverless v2):**
```typescript
new DatabaseCluster(this, 'Database', {
  engine: DatabaseClusterEngine.auroraPostgres({
    version: AuroraPostgresEngineVersion.VER_14_6
  }),
  serverlessV2MinCapacity: 0.5,
  serverlessV2MaxCapacity: 1.0,
  writer: ClusterInstance.serverlessV2('writer'),
  vpc,
  vpcSubnets: { subnetType: SubnetType.PRIVATE_WITH_EGRESS }
});
```

**Frontend Stack (Next.js):**
```typescript
new Nextjs(this, 'Frontend', {
  nextjsPath: '../../frontend',
  buildCommand: 'npm run build',
  environment: {
    NEXT_PUBLIC_API_URL: backendUrl
  }
});
```

**Network Stack:**
- VPC with public and private subnets across 2 AZs
- NAT Gateway for private subnet internet access
- Security Groups:
  - ALB: Allow 80/443 from internet
  - ECS: Allow 8000 from ALB only
  - Aurora: Allow 5432 from ECS only

**Secrets Management:**
- Database credentials in AWS Secrets Manager
- Auto-generated password on stack creation
- Injected as environment variable to ECS tasks

### Deployment Process

**Build & Push Container:**
```bash
# Login to ECR
aws ecr-public get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin public.ecr.aws

# Build and push
cd src/backend
docker build -t notes-api .
docker tag notes-api:latest {ECR_URI}:latest
docker push {ECR_URI}:latest
```

**Deploy Infrastructure:**
```bash
cd src/infra
npm install
npx cdk bootstrap  # First time only
npx cdk deploy --all
```

**Deployment Order:**
1. Network Stack (VPC, subnets, security groups)
2. Database Stack (Aurora cluster)
3. Backend Stack (ECR, ECS, ALB)
4. Frontend Stack (S3, CloudFront, Lambda@Edge)

### Production Testing Strategy

**Phase 1: AWS MCP Verification**
```bash
# Enable AWS MCP tools via Funnel
discover_tools_by_words(words="aws ecs cloudfront", enable=true)

# Verify ECS tasks running
bridge_tool_request(tool="aws__describe_services", ...)

# Check Aurora status
bridge_tool_request(tool="aws__describe_db_clusters", ...)

# Test CloudFront distribution
bridge_tool_request(tool="aws__get_distribution", ...)
```

**Phase 2: API Testing (Newman)**
```bash
# Update collection with production URL
newman run collection.json --env-var url=https://api.{domain}
```

**Phase 3: E2E Testing (Playwright)**
- Point Playwright tests to CloudFront URL
- Verify all CRUD operations work end-to-end
- Check for CORS issues

**Phase 4: Performance Testing**
- Verify Aurora scales down to 0.5 ACU when idle
- Check ECS task auto-scaling under load
- Test CloudFront cache hit ratio

### Cost Optimization

**Aurora Serverless v2:**
- Scales down to 0.5 ACU when idle (~$0.06/hour minimum)
- Automatically scales up under load
- Pauses after extended inactivity

**ECS Fargate:**
- Single task for MVP (0.25 vCPU, 0.5 GB)
- ~$8-12/month at baseline

**CloudFront + S3:**
- S3: Negligible for static assets
- CloudFront: Free tier covers MVP usage

**Total Estimated Cost:** ~$20-30/month for low-traffic MVP

## Testing Strategy Summary

### Local Testing Sequence

1. **Unit Tests** (if time permits): Test individual functions
2. **API Tests (curl)**: Manual verification of all endpoints
3. **API Tests (Newman)**: Automated Postman collection execution
4. **Database Tests (PostgreSQL MCP)**: Direct query verification
5. **E2E Tests (Playwright MCP)**: Full user flow automation

### Production Testing Sequence

1. **Infrastructure Verification (AWS MCP)**: Confirm all resources deployed
2. **API Tests (Newman)**: Automated against production endpoints
3. **E2E Tests (Playwright)**: Full user flows on CloudFront URL
4. **Performance Tests**: Aurora scaling, response times

## Success Criteria

**Functional:**
- ✅ Users can create notes with title and content
- ✅ Users can view all notes in a list
- ✅ Users can update existing notes
- ✅ Users can delete notes
- ✅ Timestamps automatically track creation and updates

**Technical:**
- ✅ Backend runs in ECS Fargate container
- ✅ Frontend deployed via CloudFront
- ✅ Aurora scales down to 0.5 ACU when idle
- ✅ All CRUD operations complete in <500ms locally
- ✅ All tests pass (curl, Newman, Playwright)

**Quality:**
- ✅ No authentication required (as specified)
- ✅ Plain CSS styling (no frameworks)
- ✅ Simple, clean UI
- ✅ Proper error handling with user-friendly messages

## Out of Scope (Future Considerations)

- User authentication/authorization
- Note sharing or collaboration
- Rich text editing
- File attachments
- Search functionality
- Tags or categories
- Bulk operations
- Pagination (acceptable for MVP with limited notes)
- Real-time updates (WebSockets)
- Offline support (PWA)

## Project Structure

```
claude-code-pro/
├── src/
│   ├── backend/
│   │   ├── main.py              # FastAPI app + routes
│   │   ├── models.py            # Pydantic/SQLModel models
│   │   ├── database.py          # DB connection + session
│   │   ├── init.sql             # Schema initialization
│   │   ├── Dockerfile           # Container definition
│   │   ├── requirements.txt     # Python dependencies
│   │   └── .env                 # Local environment vars
│   ├── frontend/
│   │   ├── app/
│   │   │   ├── page.tsx         # Main page
│   │   │   ├── layout.tsx       # Root layout
│   │   │   └── globals.css      # Global styles
│   │   ├── components/
│   │   │   ├── NoteCard.tsx
│   │   │   ├── NoteForm.tsx
│   │   │   └── NoteList.tsx
│   │   ├── types/
│   │   │   └── note.ts          # TypeScript interfaces
│   │   ├── package.json
│   │   ├── next.config.js
│   │   └── .env.local
│   └── infra/
│       ├── bin/
│       │   └── app.ts
│       ├── lib/
│       │   ├── network-stack.ts
│       │   ├── database-stack.ts
│       │   ├── backend-stack.ts
│       │   └── frontend-stack.ts
│       ├── cdk.json
│       └── package.json
├── docs/
│   └── designs/
│       └── 2025-10-29-note-taking-mvp-design.md
└── README.md
```

## Implementation Notes

**Development Approach:**
- Start with backend (database + API)
- Test backend thoroughly before frontend
- Build frontend components incrementally
- Test integration before deploying to AWS
- Deploy infrastructure in dependency order

**Key Dependencies:**
- Backend: fastapi, uvicorn, sqlmodel, asyncpg, pydantic
- Frontend: next, react, react-dom, typescript
- Infrastructure: aws-cdk-lib, cdk-nextjs

**Docker Considerations:**
- Multi-stage build for smaller image size
- Use Python 3.11-slim base image
- Copy only necessary files
- Run as non-root user for security

## Next Steps

Ready to proceed with implementation planning via `/spec-plan` command.
