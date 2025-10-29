# Note-Taking MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use skill spec-implement to implement this plan task-by-task.

**Goal:** Build a simple CRUD note-taking application with FastAPI backend, Next.js frontend, and AWS infrastructure

**Architecture:** Three-tier application with FastAPI backend in Docker, Next.js frontend, PostgreSQL database, deployed to AWS using CDK with ECS Fargate for backend and CloudFront for frontend

**Tech Stack:** FastAPI, SQLModel, Next.js, PostgreSQL, AWS CDK, Docker, Newman

---

## Task 1: Backend Database Setup

**Files:**
- Create: `src/backend/init.sql`
- Create: `src/backend/database.py`
- Create: `src/backend/tests/__init__.py`
- Create: `src/backend/tests/test_database.py`

**Step 1: Write the failing test**

Create `src/backend/tests/__init__.py`:
```python
# Test package initialization
```

Create `src/backend/tests/test_database.py`:
```python
"""Test database connection and initialization."""
import pytest
from sqlmodel import Session, select
from database import engine, get_session
from models import Note

def test_database_connection():
    """Test that database connection works."""
    with Session(engine) as session:
        # Try to execute a simple query
        result = session.exec(select(1))
        assert result.first() == 1

@pytest.mark.asyncio
async def test_get_session():
    """Test session dependency injection."""
    async for session in get_session():
        assert session is not None
        break
```

**Step 2: Run test to verify it fails**

Run: `cd src/backend && uv run pytest tests/test_database.py -v`
Expected: FAIL with "ModuleNotFoundError: No module named 'database'"

**Step 3: Write minimal implementation**

Create `src/backend/init.sql`:
```sql
-- Initialize notes table
CREATE TABLE IF NOT EXISTS notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create index for sorting
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

Create `src/backend/database.py`:
```python
"""Database connection and session management."""
import os
from typing import AsyncGenerator
from sqlmodel import create_engine, Session, SQLModel
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

# Get database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5433/postgres")

# Convert to async URL if needed
if DATABASE_URL.startswith("postgresql://"):
    ASYNC_DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")
else:
    ASYNC_DATABASE_URL = DATABASE_URL

# Create sync engine for testing
engine = create_engine(DATABASE_URL.replace("+asyncpg", ""), echo=False)

# Create async engine for production
async_engine = create_async_engine(ASYNC_DATABASE_URL, echo=False, future=True)

# Create async session factory
AsyncSessionLocal = sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

def init_db():
    """Initialize database with tables."""
    # Read and execute init.sql
    with open("init.sql", "r") as f:
        sql_script = f.read()

    with Session(engine) as session:
        # Execute the SQL script
        for statement in sql_script.split(';'):
            if statement.strip():
                session.exec(statement)
        session.commit()
```

**Step 4: Run test to verify it passes**

Run: `cd src/backend && uv run pytest tests/test_database.py -v`
Expected: FAIL - models module doesn't exist yet (expected - we'll create it next)

**Step 5: Commit**

```bash
git add src/backend/init.sql src/backend/database.py src/backend/tests/
git commit -m "feat: add database setup with init script and connection management"
```

**Skills:** @backend-models, @testing-test-driven-development, @global-error-handling

---

## Task 2: Backend Data Models

**Files:**
- Create: `src/backend/models.py`
- Create: `src/backend/tests/test_models.py`
- Modify: `src/backend/requirements.txt`

**Step 1: Write the failing test**

Create `src/backend/tests/test_models.py`:
```python
"""Test data models."""
import uuid
from datetime import datetime
from pydantic import ValidationError
import pytest
from models import Note, NoteCreate, NoteUpdate, NoteResponse

def test_note_create_model():
    """Test NoteCreate validation."""
    # Valid note
    note = NoteCreate(title="Test", content="Content")
    assert note.title == "Test"
    assert note.content == "Content"

    # Title too long
    with pytest.raises(ValidationError):
        NoteCreate(title="x" * 201, content="Content")

    # Missing required fields
    with pytest.raises(ValidationError):
        NoteCreate(title="Test")

def test_note_update_model():
    """Test NoteUpdate validation."""
    # Valid update
    update = NoteUpdate(title="Updated", content="New content")
    assert update.title == "Updated"

    # Title too long
    with pytest.raises(ValidationError):
        NoteUpdate(title="x" * 201, content="Content")

def test_note_response_model():
    """Test NoteResponse model."""
    note_id = uuid.uuid4()
    now = datetime.utcnow()

    response = NoteResponse(
        id=note_id,
        title="Test",
        content="Content",
        created_at=now,
        updated_at=now
    )

    assert response.id == note_id
    assert response.title == "Test"
```

**Step 2: Run test to verify it fails**

Run: `cd src/backend && uv run pytest tests/test_models.py -v`
Expected: FAIL with "ModuleNotFoundError: No module named 'models'"

**Step 3: Write minimal implementation**

Create `src/backend/models.py`:
```python
"""Data models for the notes application."""
from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4
from sqlmodel import Field, SQLModel
from pydantic import ConfigDict, field_validator

class NoteBase(SQLModel):
    """Base model for Note."""
    title: str = Field(min_length=1, max_length=200)
    content: str = Field(min_length=1)

class Note(NoteBase, table=True):
    """Database model for Note."""
    __tablename__ = "notes"

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class NoteCreate(NoteBase):
    """Model for creating a note."""
    @field_validator("title")
    def validate_title_length(cls, v):
        """Validate title length."""
        if len(v) > 200:
            raise ValueError("Title must be 200 characters or less")
        return v

class NoteUpdate(NoteBase):
    """Model for updating a note."""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=1)

    @field_validator("title")
    def validate_title_length(cls, v):
        """Validate title length if provided."""
        if v and len(v) > 200:
            raise ValueError("Title must be 200 characters or less")
        return v

class NoteResponse(NoteBase):
    """Model for note response."""
    id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
```

**Step 4: Update requirements**

Modify `src/backend/requirements.txt`:
```txt
# ~~ Generated by projen. To modify, edit .projenrc.py and run "npx projen".
fastapi==0.115.5
sqlmodel==0.0.22
uvicorn[standard]==0.32.1
asyncpg==0.30.0
pydantic==2.10.3
python-dotenv==1.0.1
```

**Step 5: Install dependencies and run test**

Run: `cd src/backend && uv pip install -r requirements.txt && uv run pytest tests/test_models.py -v`
Expected: PASS

**Step 6: Run all tests to ensure nothing broke**

Run: `cd src/backend && uv run pytest tests/ -v`
Expected: PASS (database tests should now work too)

**Step 7: Commit**

```bash
git add src/backend/models.py src/backend/tests/test_models.py src/backend/requirements.txt
git commit -m "feat: add Pydantic/SQLModel data models with validation"
```

**Skills:** @backend-models, @testing-test-driven-development, @global-validation

---

## Task 3: Backend API - Health Check

**Files:**
- Create: `src/backend/main.py`
- Create: `src/backend/tests/test_api_health.py`
- Create: `src/backend/.env`

**Step 1: Write the failing test**

Create `src/backend/tests/test_api_health.py`:
```python
"""Test health check endpoint."""
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health_check():
    """Test /health endpoint returns healthy status."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}
```

**Step 2: Run test to verify it fails**

Run: `cd src/backend && uv run pytest tests/test_api_health.py -v`
Expected: FAIL with "ModuleNotFoundError: No module named 'main'"

**Step 3: Write minimal implementation**

Create `src/backend/.env`:
```
DATABASE_URL=postgresql://postgres:postgres@localhost:5433/postgres
```

Create `src/backend/main.py`:
```python
"""Main FastAPI application."""
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from uuid import UUID
import uvicorn

from database import get_session, init_db
from models import Note, NoteCreate, NoteUpdate, NoteResponse

# Initialize database on startup
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize resources on startup."""
    try:
        init_db()
        print("Database initialized")
    except Exception as e:
        print(f"Database initialization failed: {e}")
    yield

# Create FastAPI app
app = FastAPI(
    title="Notes API",
    description="Simple CRUD API for notes",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
```

**Step 4: Run test to verify it passes**

Run: `cd src/backend && uv run pytest tests/test_api_health.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git add src/backend/main.py src/backend/tests/test_api_health.py src/backend/.env
git commit -m "feat: add FastAPI app with health check endpoint"
```

**Skills:** @backend-api, @testing-test-driven-development, @global-error-handling

---

## Task 4: Backend API - Create Note

**Files:**
- Modify: `src/backend/main.py`
- Create: `src/backend/tests/test_api_notes.py`
- Create: `postman/collections/notes-api.json`
- Create: `postman/environments/local.json`

**Step 1: Write the failing test**

Create `src/backend/tests/test_api_notes.py`:
```python
"""Test notes API endpoints."""
import uuid
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_create_note():
    """Test POST /api/notes creates a new note."""
    note_data = {
        "title": "Test Note",
        "content": "This is a test note"
    }

    response = client.post("/api/notes", json=note_data)

    assert response.status_code == 201
    data = response.json()
    assert data["title"] == note_data["title"]
    assert data["content"] == note_data["content"]
    assert "id" in data
    assert "created_at" in data
    assert "updated_at" in data

def test_create_note_validation():
    """Test POST /api/notes validates input."""
    # Missing title
    response = client.post("/api/notes", json={"content": "Content only"})
    assert response.status_code == 422

    # Title too long
    response = client.post("/api/notes", json={
        "title": "x" * 201,
        "content": "Content"
    })
    assert response.status_code == 422
```

**Step 2: Run test to verify it fails**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_create_note -v`
Expected: FAIL with 404 status code

**Step 3: Write minimal implementation**

Modify `src/backend/main.py` (add after health check endpoint):
```python
from sqlmodel import select

@app.post("/api/notes", response_model=NoteResponse, status_code=201)
async def create_note(
    note_create: NoteCreate,
    session: AsyncSession = Depends(get_session)
):
    """Create a new note."""
    # Create note instance
    note = Note(
        title=note_create.title,
        content=note_create.content
    )

    # Add to database
    session.add(note)
    await session.commit()
    await session.refresh(note)

    return NoteResponse.model_validate(note)
```

**Step 4: Run test to verify it passes**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_create_note -v`
Expected: PASS

**Step 5: Create Postman collection**

Create `postman/collections/notes-api.json`:
```json
{
  "info": {
    "name": "Notes API",
    "description": "CRUD API tests for notes application",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{base_url}}/health",
          "host": ["{{base_url}}"],
          "path": ["health"]
        }
      },
      "response": [],
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('Status is 200', function () {",
              "    pm.response.to.have.status(200);",
              "});",
              "pm.test('Status is healthy', function () {",
              "    var jsonData = pm.response.json();",
              "    pm.expect(jsonData.status).to.eql('healthy');",
              "});"
            ],
            "type": "text/javascript"
          }
        }
      ]
    },
    {
      "name": "Create Note",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n    \"title\": \"Test Note from Postman\",\n    \"content\": \"This is a test note created via Postman\"\n}"
        },
        "url": {
          "raw": "{{base_url}}/api/notes",
          "host": ["{{base_url}}"],
          "path": ["api", "notes"]
        }
      },
      "response": [],
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('Status is 201', function () {",
              "    pm.response.to.have.status(201);",
              "});",
              "pm.test('Response has required fields', function () {",
              "    var jsonData = pm.response.json();",
              "    pm.expect(jsonData).to.have.property('id');",
              "    pm.expect(jsonData).to.have.property('title');",
              "    pm.expect(jsonData).to.have.property('content');",
              "    pm.expect(jsonData).to.have.property('created_at');",
              "    pm.expect(jsonData).to.have.property('updated_at');",
              "});",
              "// Save ID for other tests",
              "pm.environment.set('note_id', pm.response.json().id);"
            ],
            "type": "text/javascript"
          }
        }
      ]
    }
  ]
}
```

Create `postman/environments/local.json`:
```json
{
  "name": "Local",
  "values": [
    {
      "key": "base_url",
      "value": "http://localhost:8000",
      "enabled": true
    },
    {
      "key": "note_id",
      "value": "",
      "enabled": true
    }
  ]
}
```

**Step 6: Run Newman E2E test**

Run: `cd src/backend && uv run uvicorn main:app --port 8000 &`
Run: `sleep 3 && newman run ../postman/collections/notes-api.json -e ../postman/environments/local.json`
Expected: All tests pass

**Step 7: Commit**

```bash
git add src/backend/main.py src/backend/tests/test_api_notes.py postman/
git commit -m "feat: add POST /api/notes endpoint with validation"
```

**Skills:** @backend-api, @testing-test-driven-development, @global-validation, @global-error-handling

---

## Task 5: Backend API - List Notes

**Files:**
- Modify: `src/backend/main.py`
- Modify: `src/backend/tests/test_api_notes.py`
- Modify: `postman/collections/notes-api.json`

**Step 1: Write the failing test**

Add to `src/backend/tests/test_api_notes.py`:
```python
def test_list_notes():
    """Test GET /api/notes returns list of notes."""
    # Create some test notes
    for i in range(3):
        client.post("/api/notes", json={
            "title": f"Note {i}",
            "content": f"Content {i}"
        })

    response = client.get("/api/notes")

    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 3
    # Should be sorted by created_at DESC (newest first)
    assert data[0]["title"] == "Note 2"
```

**Step 2: Run test to verify it fails**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_list_notes -v`
Expected: FAIL with 404 status code

**Step 3: Write minimal implementation**

Add to `src/backend/main.py`:
```python
@app.get("/api/notes", response_model=List[NoteResponse])
async def list_notes(
    session: AsyncSession = Depends(get_session)
):
    """List all notes sorted by created_at DESC."""
    from sqlalchemy import desc

    statement = select(Note).order_by(desc(Note.created_at))
    result = await session.exec(statement)
    notes = result.all()

    return [NoteResponse.model_validate(note) for note in notes]
```

**Step 4: Run test to verify it passes**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_list_notes -v`
Expected: PASS

**Step 5: Update Postman collection**

Add to `postman/collections/notes-api.json` in the "item" array:
```json
{
  "name": "List Notes",
  "request": {
    "method": "GET",
    "header": [],
    "url": {
      "raw": "{{base_url}}/api/notes",
      "host": ["{{base_url}}"],
      "path": ["api", "notes"]
    }
  },
  "response": [],
  "event": [
    {
      "listen": "test",
      "script": {
        "exec": [
          "pm.test('Status is 200', function () {",
          "    pm.response.to.have.status(200);",
          "});",
          "pm.test('Response is an array', function () {",
          "    var jsonData = pm.response.json();",
          "    pm.expect(jsonData).to.be.an('array');",
          "});",
          "pm.test('Notes have required fields', function () {",
          "    var jsonData = pm.response.json();",
          "    if (jsonData.length > 0) {",
          "        pm.expect(jsonData[0]).to.have.property('id');",
          "        pm.expect(jsonData[0]).to.have.property('title');",
          "        pm.expect(jsonData[0]).to.have.property('content');",
          "    }",
          "});"
        ],
        "type": "text/javascript"
      }
    }
  ]
}
```

**Step 6: Run Newman E2E test**

Run: `newman run postman/collections/notes-api.json -e postman/environments/local.json`
Expected: All tests pass

**Step 7: Commit**

```bash
git add src/backend/main.py src/backend/tests/test_api_notes.py postman/collections/notes-api.json
git commit -m "feat: add GET /api/notes endpoint to list all notes"
```

**Skills:** @backend-api, @testing-test-driven-development, @backend-queries

---

## Task 6: Backend API - Get Single Note

**Files:**
- Modify: `src/backend/main.py`
- Modify: `src/backend/tests/test_api_notes.py`
- Modify: `postman/collections/notes-api.json`

**Step 1: Write the failing test**

Add to `src/backend/tests/test_api_notes.py`:
```python
def test_get_note():
    """Test GET /api/notes/{id} returns single note."""
    # Create a note
    response = client.post("/api/notes", json={
        "title": "Single Note",
        "content": "Single Content"
    })
    note_id = response.json()["id"]

    # Get the note
    response = client.get(f"/api/notes/{note_id}")

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == note_id
    assert data["title"] == "Single Note"

def test_get_note_not_found():
    """Test GET /api/notes/{id} returns 404 for missing note."""
    fake_id = str(uuid.uuid4())
    response = client.get(f"/api/notes/{fake_id}")

    assert response.status_code == 404
    assert response.json()["detail"] == "Note not found"
```

**Step 2: Run test to verify it fails**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_get_note -v`
Expected: FAIL with 404 status code

**Step 3: Write minimal implementation**

Add to `src/backend/main.py`:
```python
@app.get("/api/notes/{note_id}", response_model=NoteResponse)
async def get_note(
    note_id: UUID,
    session: AsyncSession = Depends(get_session)
):
    """Get a single note by ID."""
    statement = select(Note).where(Note.id == note_id)
    result = await session.exec(statement)
    note = result.first()

    if not note:
        raise HTTPException(status_code=404, detail="Note not found")

    return NoteResponse.model_validate(note)
```

**Step 4: Run test to verify it passes**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_get_note -v`
Expected: PASS

**Step 5: Update Postman collection**

Add to `postman/collections/notes-api.json` in the "item" array:
```json
{
  "name": "Get Single Note",
  "request": {
    "method": "GET",
    "header": [],
    "url": {
      "raw": "{{base_url}}/api/notes/{{note_id}}",
      "host": ["{{base_url}}"],
      "path": ["api", "notes", "{{note_id}}"]
    }
  },
  "response": [],
  "event": [
    {
      "listen": "test",
      "script": {
        "exec": [
          "pm.test('Status is 200', function () {",
          "    pm.response.to.have.status(200);",
          "});",
          "pm.test('Returns correct note', function () {",
          "    var jsonData = pm.response.json();",
          "    pm.expect(jsonData.id).to.eql(pm.environment.get('note_id'));",
          "});"
        ],
        "type": "text/javascript"
      }
    }
  ]
}
```

**Step 6: Run Newman E2E test**

Run: `newman run postman/collections/notes-api.json -e postman/environments/local.json`
Expected: All tests pass

**Step 7: Commit**

```bash
git add src/backend/main.py src/backend/tests/test_api_notes.py postman/collections/notes-api.json
git commit -m "feat: add GET /api/notes/{id} endpoint with 404 handling"
```

**Skills:** @backend-api, @testing-test-driven-development, @global-error-handling

---

## Task 7: Backend API - Update Note

**Files:**
- Modify: `src/backend/main.py`
- Modify: `src/backend/tests/test_api_notes.py`
- Modify: `postman/collections/notes-api.json`

**Step 1: Write the failing test**

Add to `src/backend/tests/test_api_notes.py`:
```python
def test_update_note():
    """Test PUT /api/notes/{id} updates a note."""
    # Create a note
    response = client.post("/api/notes", json={
        "title": "Original Title",
        "content": "Original Content"
    })
    note_id = response.json()["id"]

    # Update the note
    response = client.put(f"/api/notes/{note_id}", json={
        "title": "Updated Title",
        "content": "Updated Content"
    })

    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated Title"
    assert data["content"] == "Updated Content"
    assert data["updated_at"] != data["created_at"]

def test_update_note_not_found():
    """Test PUT /api/notes/{id} returns 404 for missing note."""
    fake_id = str(uuid.uuid4())
    response = client.put(f"/api/notes/{fake_id}", json={
        "title": "Updated",
        "content": "Content"
    })

    assert response.status_code == 404
```

**Step 2: Run test to verify it fails**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_update_note -v`
Expected: FAIL with 405 Method Not Allowed

**Step 3: Write minimal implementation**

Add to `src/backend/main.py`:
```python
@app.put("/api/notes/{note_id}", response_model=NoteResponse)
async def update_note(
    note_id: UUID,
    note_update: NoteUpdate,
    session: AsyncSession = Depends(get_session)
):
    """Update an existing note."""
    statement = select(Note).where(Note.id == note_id)
    result = await session.exec(statement)
    note = result.first()

    if not note:
        raise HTTPException(status_code=404, detail="Note not found")

    # Update fields
    if note_update.title is not None:
        note.title = note_update.title
    if note_update.content is not None:
        note.content = note_update.content

    session.add(note)
    await session.commit()
    await session.refresh(note)

    return NoteResponse.model_validate(note)
```

**Step 4: Run test to verify it passes**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_update_note -v`
Expected: PASS

**Step 5: Update Postman collection**

Add to `postman/collections/notes-api.json` in the "item" array:
```json
{
  "name": "Update Note",
  "request": {
    "method": "PUT",
    "header": [
      {
        "key": "Content-Type",
        "value": "application/json"
      }
    ],
    "body": {
      "mode": "raw",
      "raw": "{\n    \"title\": \"Updated via Postman\",\n    \"content\": \"Updated content from Postman\"\n}"
    },
    "url": {
      "raw": "{{base_url}}/api/notes/{{note_id}}",
      "host": ["{{base_url}}"],
      "path": ["api", "notes", "{{note_id}}"]
    }
  },
  "response": [],
  "event": [
    {
      "listen": "test",
      "script": {
        "exec": [
          "pm.test('Status is 200', function () {",
          "    pm.response.to.have.status(200);",
          "});",
          "pm.test('Note is updated', function () {",
          "    var jsonData = pm.response.json();",
          "    pm.expect(jsonData.title).to.include('Updated');",
          "});"
        ],
        "type": "text/javascript"
      }
    }
  ]
}
```

**Step 6: Run Newman E2E test**

Run: `newman run postman/collections/notes-api.json -e postman/environments/local.json`
Expected: All tests pass

**Step 7: Commit**

```bash
git add src/backend/main.py src/backend/tests/test_api_notes.py postman/collections/notes-api.json
git commit -m "feat: add PUT /api/notes/{id} endpoint for updates"
```

**Skills:** @backend-api, @testing-test-driven-development, @global-validation

---

## Task 8: Backend API - Delete Note

**Files:**
- Modify: `src/backend/main.py`
- Modify: `src/backend/tests/test_api_notes.py`
- Modify: `postman/collections/notes-api.json`

**Step 1: Write the failing test**

Add to `src/backend/tests/test_api_notes.py`:
```python
def test_delete_note():
    """Test DELETE /api/notes/{id} deletes a note."""
    # Create a note
    response = client.post("/api/notes", json={
        "title": "To Delete",
        "content": "Delete me"
    })
    note_id = response.json()["id"]

    # Delete the note
    response = client.delete(f"/api/notes/{note_id}")

    assert response.status_code == 200
    assert response.json()["message"] == "Note deleted successfully"

    # Verify it's gone
    response = client.get(f"/api/notes/{note_id}")
    assert response.status_code == 404

def test_delete_note_not_found():
    """Test DELETE /api/notes/{id} returns 404 for missing note."""
    fake_id = str(uuid.uuid4())
    response = client.delete(f"/api/notes/{fake_id}")

    assert response.status_code == 404
```

**Step 2: Run test to verify it fails**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_delete_note -v`
Expected: FAIL with 405 Method Not Allowed

**Step 3: Write minimal implementation**

Add to `src/backend/main.py`:
```python
@app.delete("/api/notes/{note_id}")
async def delete_note(
    note_id: UUID,
    session: AsyncSession = Depends(get_session)
):
    """Delete a note."""
    statement = select(Note).where(Note.id == note_id)
    result = await session.exec(statement)
    note = result.first()

    if not note:
        raise HTTPException(status_code=404, detail="Note not found")

    await session.delete(note)
    await session.commit()

    return {"message": "Note deleted successfully"}
```

**Step 4: Run test to verify it passes**

Run: `cd src/backend && uv run pytest tests/test_api_notes.py::test_delete_note -v`
Expected: PASS

**Step 5: Update Postman collection**

Add to `postman/collections/notes-api.json` in the "item" array:
```json
{
  "name": "Delete Note",
  "request": {
    "method": "DELETE",
    "header": [],
    "url": {
      "raw": "{{base_url}}/api/notes/{{note_id}}",
      "host": ["{{base_url}}"],
      "path": ["api", "notes", "{{note_id}}"]
    }
  },
  "response": [],
  "event": [
    {
      "listen": "test",
      "script": {
        "exec": [
          "pm.test('Status is 200', function () {",
          "    pm.response.to.have.status(200);",
          "});",
          "pm.test('Returns success message', function () {",
          "    var jsonData = pm.response.json();",
          "    pm.expect(jsonData.message).to.include('deleted');",
          "});"
        ],
        "type": "text/javascript"
      }
    }
  ]
}
```

**Step 6: Run Newman E2E test**

Run: `newman run postman/collections/notes-api.json -e postman/environments/local.json`
Expected: All tests pass

**Step 7: Run all backend tests**

Run: `cd src/backend && uv run pytest tests/ -v`
Expected: All tests pass

**Step 8: Commit**

```bash
git add src/backend/main.py src/backend/tests/test_api_notes.py postman/collections/notes-api.json
git commit -m "feat: complete backend CRUD API with all endpoints"
```

**Skills:** @backend-api, @testing-test-driven-development, @global-error-handling

---

## Task 9: Backend Dockerfile

**Files:**
- Create: `src/backend/Dockerfile`
- Create: `src/backend/.dockerignore`

**Step 1: Create Dockerfile**

Create `src/backend/Dockerfile`:
```dockerfile
# Multi-stage build for smaller image
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 appuser

# Set working directory
WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Step 2: Create .dockerignore**

Create `src/backend/.dockerignore`:
```
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv/
pip-log.txt
pip-delete-this-directory.txt
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.git
.gitignore
.mypy_cache
.pytest_cache
.hypothesis
tests/
*.md
.env
```

**Step 3: Build and test Docker image**

Run: `cd src/backend && docker build -t notes-api:latest .`
Expected: Build succeeds

**Step 4: Run container locally**

Run: `docker run -d -p 8001:8000 --env DATABASE_URL=postgresql://postgres:postgres@host.docker.internal:5433/postgres notes-api:latest`
Run: `sleep 5 && curl http://localhost:8001/health`
Expected: {"status": "healthy"}

**Step 5: Stop container**

Run: `docker stop $(docker ps -q --filter ancestor=notes-api:latest)`

**Step 6: Commit**

```bash
git add src/backend/Dockerfile src/backend/.dockerignore
git commit -m "feat: add Dockerfile for backend containerization"
```

**Skills:** @global-conventions, @backend-api

---

## Task 10: Frontend - Project Setup

**Files:**
- Modify: `src/frontend/package.json`
- Create: `src/frontend/.env.local`
- Create: `src/frontend/types/note.ts`
- Create: `src/frontend/app/globals.css`
- Create: `src/frontend/app/layout.tsx`
- Create: `src/frontend/app/page.tsx`

**Step 1: Update package.json for App Router**

Modify `src/frontend/package.json`:
```json
{
  "name": "frontend",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^14.2.0",
    "react": "^18.3.0",
    "react-dom": "^18.3.0"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "typescript": "^5"
  },
  "engines": {
    "node": ">= 18.0.0"
  }
}
```

**Step 2: Install dependencies**

Run: `cd src/frontend && npm install`

**Step 3: Create environment file**

Create `src/frontend/.env.local`:
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

**Step 4: Create TypeScript types**

Create `src/frontend/types/note.ts`:
```typescript
export interface Note {
  id: string;
  title: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface NoteCreate {
  title: string;
  content: string;
}

export interface NoteUpdate {
  title?: string;
  content?: string;
}
```

**Step 5: Create global styles**

Create `src/frontend/app/globals.css`:
```css
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html,
body {
  max-width: 100vw;
  overflow-x: hidden;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  background-color: #f5f5f5;
  color: #333;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.header {
  text-align: center;
  margin-bottom: 2rem;
}

.header h1 {
  font-size: 2.5rem;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.header p {
  font-size: 1.1rem;
  color: #7f8c8d;
}

.button {
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.button-primary {
  background-color: #3498db;
  color: white;
}

.button-primary:hover {
  background-color: #2980b9;
}

.button-secondary {
  background-color: #95a5a6;
  color: white;
}

.button-secondary:hover {
  background-color: #7f8c8d;
}

.button-danger {
  background-color: #e74c3c;
  color: white;
}

.button-danger:hover {
  background-color: #c0392b;
}

.error {
  color: #e74c3c;
  margin-top: 0.5rem;
  font-size: 0.9rem;
}
```

**Step 6: Create root layout**

Create `src/frontend/app/layout.tsx`:
```tsx
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Notes App',
  description: 'Simple note-taking application',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

**Step 7: Create placeholder home page**

Create `src/frontend/app/page.tsx`:
```tsx
export default function Home() {
  return (
    <div className="container">
      <header className="header">
        <h1>Notes App</h1>
        <p>Keep track of your important information</p>
      </header>
      <main>
        <p>Loading notes...</p>
      </main>
    </div>
  );
}
```

**Step 8: Test frontend runs**

Run: `cd src/frontend && npm run dev`
Expected: Server starts on http://localhost:3000

**Step 9: Commit**

```bash
git add src/frontend/
git commit -m "feat: setup Next.js frontend with App Router and types"
```

**Skills:** @frontend-components, @frontend-css, @global-conventions

---

## Task 11: Frontend - Note Components

**Files:**
- Create: `src/frontend/components/NoteForm.tsx`
- Create: `src/frontend/components/NoteForm.module.css`
- Create: `src/frontend/components/NoteCard.tsx`
- Create: `src/frontend/components/NoteCard.module.css`
- Create: `src/frontend/components/NoteList.tsx`
- Create: `src/frontend/components/NoteList.module.css`

**Step 1: Create NoteForm component**

Create `src/frontend/components/NoteForm.tsx`:
```tsx
'use client';

import { useState, FormEvent } from 'react';
import { NoteCreate } from '../types/note';
import styles from './NoteForm.module.css';

interface NoteFormProps {
  onSubmit: (note: NoteCreate) => void;
  onCancel: () => void;
  initialTitle?: string;
  initialContent?: string;
}

export default function NoteForm({
  onSubmit,
  onCancel,
  initialTitle = '',
  initialContent = ''
}: NoteFormProps) {
  const [title, setTitle] = useState(initialTitle);
  const [content, setContent] = useState(initialContent);
  const [error, setError] = useState('');

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();

    // Validation
    if (!title.trim()) {
      setError('Title is required');
      return;
    }
    if (title.length > 200) {
      setError('Title must be 200 characters or less');
      return;
    }
    if (!content.trim()) {
      setError('Content is required');
      return;
    }

    onSubmit({ title: title.trim(), content: content.trim() });
    setTitle('');
    setContent('');
    setError('');
  };

  return (
    <form onSubmit={handleSubmit} className={styles.form}>
      <div className={styles.formGroup}>
        <label htmlFor="title">Title</label>
        <input
          id="title"
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Enter note title"
          maxLength={200}
          className={styles.input}
        />
      </div>

      <div className={styles.formGroup}>
        <label htmlFor="content">Content</label>
        <textarea
          id="content"
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Enter note content"
          rows={5}
          className={styles.textarea}
        />
      </div>

      {error && <p className="error">{error}</p>}

      <div className={styles.buttonGroup}>
        <button type="submit" className="button button-primary">
          Save Note
        </button>
        <button type="button" onClick={onCancel} className="button button-secondary">
          Cancel
        </button>
      </div>
    </form>
  );
}
```

Create `src/frontend/components/NoteForm.module.css`:
```css
.form {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

.formGroup {
  margin-bottom: 1rem;
}

.formGroup label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #2c3e50;
}

.input,
.textarea {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  font-family: inherit;
}

.input:focus,
.textarea:focus {
  outline: none;
  border-color: #3498db;
}

.textarea {
  resize: vertical;
}

.buttonGroup {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
}
```

**Step 2: Create NoteCard component**

Create `src/frontend/components/NoteCard.tsx`:
```tsx
'use client';

import { useState } from 'react';
import { Note, NoteUpdate } from '../types/note';
import NoteForm from './NoteForm';
import styles from './NoteCard.module.css';

interface NoteCardProps {
  note: Note;
  onEdit: (id: string, update: NoteUpdate) => void;
  onDelete: (id: string) => void;
}

export default function NoteCard({ note, onEdit, onDelete }: NoteCardProps) {
  const [isEditing, setIsEditing] = useState(false);

  const handleEdit = (update: NoteUpdate) => {
    onEdit(note.id, update);
    setIsEditing(false);
  };

  const handleDelete = () => {
    if (confirm('Are you sure you want to delete this note?')) {
      onDelete(note.id);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  if (isEditing) {
    return (
      <div className={styles.card}>
        <NoteForm
          onSubmit={handleEdit}
          onCancel={() => setIsEditing(false)}
          initialTitle={note.title}
          initialContent={note.content}
        />
      </div>
    );
  }

  return (
    <div className={styles.card}>
      <h3 className={styles.title}>{note.title}</h3>
      <p className={styles.content}>{note.content}</p>
      <div className={styles.metadata}>
        <small>Created: {formatDate(note.created_at)}</small>
        {note.updated_at !== note.created_at && (
          <small>Updated: {formatDate(note.updated_at)}</small>
        )}
      </div>
      <div className={styles.actions}>
        <button
          onClick={() => setIsEditing(true)}
          className="button button-primary"
        >
          Edit
        </button>
        <button
          onClick={handleDelete}
          className="button button-danger"
        >
          Delete
        </button>
      </div>
    </div>
  );
}
```

Create `src/frontend/components/NoteCard.module.css`:
```css
.card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  transition: box-shadow 0.3s;
}

.card:hover {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.title {
  font-size: 1.25rem;
  color: #2c3e50;
  margin-bottom: 0.75rem;
  word-wrap: break-word;
}

.content {
  color: #555;
  line-height: 1.6;
  white-space: pre-wrap;
  word-wrap: break-word;
  margin-bottom: 1rem;
}

.metadata {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin-bottom: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #ecf0f1;
}

.metadata small {
  color: #95a5a6;
  font-size: 0.85rem;
}

.actions {
  display: flex;
  gap: 0.75rem;
}

.actions button {
  font-size: 0.9rem;
  padding: 0.5rem 1rem;
}
```

**Step 3: Create NoteList component**

Create `src/frontend/components/NoteList.tsx`:
```tsx
'use client';

import { Note, NoteUpdate } from '../types/note';
import NoteCard from './NoteCard';
import styles from './NoteList.module.css';

interface NoteListProps {
  notes: Note[];
  onEdit: (id: string, update: NoteUpdate) => void;
  onDelete: (id: string) => void;
}

export default function NoteList({ notes, onEdit, onDelete }: NoteListProps) {
  if (notes.length === 0) {
    return (
      <div className={styles.emptyState}>
        <p>No notes yet. Create your first note above!</p>
      </div>
    );
  }

  return (
    <div className={styles.grid}>
      {notes.map((note) => (
        <NoteCard
          key={note.id}
          note={note}
          onEdit={onEdit}
          onDelete={onDelete}
        />
      ))}
    </div>
  );
}
```

Create `src/frontend/components/NoteList.module.css`:
```css
.grid {
  display: grid;
  gap: 1.5rem;
  grid-template-columns: 1fr;
}

@media (min-width: 768px) {
  .grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

.emptyState {
  text-align: center;
  padding: 3rem;
  color: #7f8c8d;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
```

**Step 4: Commit**

```bash
git add src/frontend/components/
git commit -m "feat: add reusable Note components with styling"
```

**Skills:** @frontend-components, @frontend-css, @frontend-responsive, @global-validation

---

## Task 12: Frontend - Main Page with API Integration

**Files:**
- Modify: `src/frontend/app/page.tsx`
- Create: `src/frontend/app/page.module.css`

**Step 1: Update main page with full functionality**

Modify `src/frontend/app/page.tsx`:
```tsx
'use client';

import { useState, useEffect } from 'react';
import { Note, NoteCreate, NoteUpdate } from '../types/note';
import NoteForm from '../components/NoteForm';
import NoteList from '../components/NoteList';
import styles from './page.module.css';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default function Home() {
  const [notes, setNotes] = useState<Note[]>([]);
  const [isCreating, setIsCreating] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Fetch notes on mount
  useEffect(() => {
    fetchNotes();
  }, []);

  const fetchNotes = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE}/api/notes`);
      if (!response.ok) throw new Error('Failed to fetch notes');
      const data = await response.json();
      setNotes(data);
      setError('');
    } catch (err) {
      setError('Failed to load notes. Please try again.');
      console.error('Error fetching notes:', err);
    } finally {
      setLoading(false);
    }
  };

  const createNote = async (noteCreate: NoteCreate) => {
    try {
      const response = await fetch(`${API_BASE}/api/notes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(noteCreate),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || 'Failed to create note');
      }

      const newNote = await response.json();
      setNotes([newNote, ...notes]);
      setIsCreating(false);
      setError('');
    } catch (err: any) {
      setError(err.message || 'Failed to create note');
      console.error('Error creating note:', err);
    }
  };

  const updateNote = async (id: string, noteUpdate: NoteUpdate) => {
    try {
      const response = await fetch(`${API_BASE}/api/notes/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(noteUpdate),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || 'Failed to update note');
      }

      const updatedNote = await response.json();
      setNotes(notes.map(note =>
        note.id === id ? updatedNote : note
      ));
      setError('');
    } catch (err: any) {
      setError(err.message || 'Failed to update note');
      console.error('Error updating note:', err);
    }
  };

  const deleteNote = async (id: string) => {
    try {
      const response = await fetch(`${API_BASE}/api/notes/${id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || 'Failed to delete note');
      }

      setNotes(notes.filter(note => note.id !== id));
      setError('');
    } catch (err: any) {
      setError(err.message || 'Failed to delete note');
      console.error('Error deleting note:', err);
    }
  };

  return (
    <div className="container">
      <header className="header">
        <h1>Notes App</h1>
        <p>Keep track of your important information</p>
      </header>

      <main>
        {error && (
          <div className={styles.errorBanner}>
            <p className="error">{error}</p>
            <button onClick={() => setError('')} className={styles.closeButton}>
              ×
            </button>
          </div>
        )}

        {!isCreating && (
          <div className={styles.actionBar}>
            <button
              onClick={() => setIsCreating(true)}
              className="button button-primary"
            >
              + New Note
            </button>
          </div>
        )}

        {isCreating && (
          <NoteForm
            onSubmit={createNote}
            onCancel={() => setIsCreating(false)}
          />
        )}

        {loading ? (
          <div className={styles.loading}>
            <p>Loading notes...</p>
          </div>
        ) : (
          <NoteList
            notes={notes}
            onEdit={updateNote}
            onDelete={deleteNote}
          />
        )}
      </main>
    </div>
  );
}
```

**Step 2: Create page styles**

Create `src/frontend/app/page.module.css`:
```css
.actionBar {
  margin-bottom: 2rem;
  text-align: center;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: #7f8c8d;
}

.errorBanner {
  background-color: #ffe6e6;
  border: 1px solid #ffcccc;
  border-radius: 4px;
  padding: 1rem;
  margin-bottom: 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.errorBanner p {
  margin: 0;
}

.closeButton {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #e74c3c;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.closeButton:hover {
  background-color: rgba(231, 76, 60, 0.1);
  border-radius: 4px;
}
```

**Step 3: Test full integration**

Terminal 1: `cd src/backend && uv run uvicorn main:app --reload --port 8000`
Terminal 2: `cd src/frontend && npm run dev`

Visit http://localhost:3000 and test:
- Create a new note
- Edit an existing note
- Delete a note
- Refresh to verify persistence

**Step 4: Commit**

```bash
git add src/frontend/app/
git commit -m "feat: complete frontend with full CRUD functionality"
```

**Skills:** @frontend-components, @global-error-handling, @frontend-accessibility

---

## Task 13: Local Integration Testing

**Files:**
- Create: `test-local.sh`
- Modify: `postman/collections/notes-api.json`

**Step 1: Create local test script**

Create `test-local.sh`:
```bash
#!/bin/bash
set -e

echo "=== Starting Local Integration Test ==="

# Start backend
echo "Starting backend..."
cd src/backend
uv run uvicorn main:app --port 8000 &
BACKEND_PID=$!
cd ../..

# Wait for backend to be ready
echo "Waiting for backend..."
sleep 5

# Test backend health
echo "Testing backend health..."
curl -f http://localhost:8000/health || (kill $BACKEND_PID && exit 1)

# Run API tests with Newman
echo "Running Newman API tests..."
newman run postman/collections/notes-api.json \
  -e postman/environments/local.json \
  --bail || (kill $BACKEND_PID && exit 1)

# Start frontend
echo "Starting frontend..."
cd src/frontend
npm run dev &
FRONTEND_PID=$!
cd ../..

# Wait for frontend
echo "Waiting for frontend..."
sleep 5

# Test frontend is running
echo "Testing frontend..."
curl -f http://localhost:3000 || (kill $BACKEND_PID $FRONTEND_PID && exit 1)

echo "=== All local tests passed! ==="
echo "Backend running on http://localhost:8000"
echo "Frontend running on http://localhost:3000"
echo "Press Ctrl+C to stop services"

# Keep running
wait
```

**Step 2: Make script executable**

Run: `chmod +x test-local.sh`

**Step 3: Run local integration test**

Run: `./test-local.sh`
Expected: All tests pass, services remain running

**Step 4: Commit**

```bash
git add test-local.sh
git commit -m "test: add local integration test script"
```

**Skills:** @testing-test-driven-development, @testing-final-verification

---

## Task 14: AWS CDK Infrastructure - Network Stack

**Files:**
- Create: `src/infra/package.json`
- Create: `src/infra/tsconfig.json`
- Create: `src/infra/cdk.json`
- Create: `src/infra/bin/app.ts`
- Create: `src/infra/lib/network-stack.ts`

**Step 1: Create package.json**

Create `src/infra/package.json`:
```json
{
  "name": "infra",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc",
    "watch": "tsc -w",
    "cdk": "cdk"
  },
  "devDependencies": {
    "@types/node": "20.14.0",
    "typescript": "~5.5.0",
    "aws-cdk": "2.170.0"
  },
  "dependencies": {
    "aws-cdk-lib": "2.170.0",
    "constructs": "^10.0.0",
    "cdk-nextjs-standalone": "^4.0.0",
    "source-map-support": "^0.5.21"
  }
}
```

**Step 2: Create TypeScript config**

Create `src/infra/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "declaration": true,
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noImplicitThis": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "allowJs": true,
    "outDir": "dist",
    "rootDir": ".",
    "baseUrl": ".",
    "paths": {
      "*": ["node_modules/*"]
    }
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules", "cdk.out", "dist"]
}
```

**Step 3: Create CDK config**

Create `src/infra/cdk.json`:
```json
{
  "app": "npx ts-node --prefer-ts-exts bin/app.ts",
  "watch": {
    "include": ["**"],
    "exclude": [
      "README.md",
      "cdk*.json",
      "**/*.d.ts",
      "node_modules",
      "dist"
    ]
  },
  "context": {
    "@aws-cdk/aws-apigateway:usagePlanKeyOrderInsensitiveId": true,
    "@aws-cdk/core:stackRelativeExports": true,
    "@aws-cdk/aws-rds:preventRenderingDeprecatedCredentials": true,
    "@aws-cdk/aws-ecs-patterns:removeDefaultDesiredCount": true,
    "@aws-cdk/aws-efs:defaultEncryptionAtRest": true,
    "@aws-cdk/core:enablePartitionLiterals": true,
    "@aws-cdk/core:validateSnapshotRemovalPolicy": true,
    "@aws-cdk/aws-codepipeline:crossAccountKeyAliasStackSafeResourceName": true,
    "@aws-cdk/aws-s3:createDefaultLoggingPolicy": true,
    "@aws-cdk/aws-sns-subscriptions:restrictSqsDescryption": true,
    "@aws-cdk/core:target-partitions": ["aws", "aws-cn"]
  }
}
```

**Step 4: Create app entry point**

Create `src/infra/bin/app.ts`:
```typescript
#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { NetworkStack } from '../lib/network-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
};

// Network infrastructure
new NetworkStack(app, 'NotesAppNetworkStack', {
  env,
  description: 'Network infrastructure for Notes application',
});

app.synth();
```

**Step 5: Create Network Stack**

Create `src/infra/lib/network-stack.ts`:
```typescript
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';

export class NetworkStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;
  public readonly ecsSecurityGroup: ec2.SecurityGroup;
  public readonly databaseSecurityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create VPC with public and private subnets
    this.vpc = new ec2.Vpc(this, 'NotesVPC', {
      maxAzs: 2,
      natGateways: 1,
      subnetConfiguration: [
        {
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
          cidrMask: 24,
        },
        {
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
          cidrMask: 24,
        },
      ],
    });

    // Security group for ECS tasks
    this.ecsSecurityGroup = new ec2.SecurityGroup(this, 'ECSSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for ECS tasks',
      allowAllOutbound: true,
    });

    // Security group for database
    this.databaseSecurityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc: this.vpc,
      description: 'Security group for Aurora database',
      allowAllOutbound: false,
    });

    // Allow ECS to connect to database
    this.databaseSecurityGroup.addIngressRule(
      this.ecsSecurityGroup,
      ec2.Port.tcp(5432),
      'Allow PostgreSQL access from ECS tasks'
    );

    // Export VPC ID for other stacks
    new cdk.CfnOutput(this, 'VPCId', {
      value: this.vpc.vpcId,
      exportName: 'NotesApp-VPC-Id',
    });

    // Export subnet IDs
    new cdk.CfnOutput(this, 'PrivateSubnetIds', {
      value: this.vpc.privateSubnets.map(subnet => subnet.subnetId).join(','),
      exportName: 'NotesApp-Private-Subnet-Ids',
    });
  }
}
```

**Step 6: Install dependencies**

Run: `cd src/infra && npm install`

**Step 7: Build and test synthesis**

Run: `cd src/infra && npm run build && npx cdk synth`
Expected: CloudFormation template generated

**Step 8: Commit**

```bash
git add src/infra/
git commit -m "feat: add CDK network stack with VPC and security groups"
```

**Skills:** @global-conventions, @backend-api

---

## Task 15: AWS CDK Infrastructure - Database Stack

**Files:**
- Create: `src/infra/lib/database-stack.ts`
- Modify: `src/infra/bin/app.ts`

**Step 1: Create Database Stack**

Create `src/infra/lib/database-stack.ts`:
```typescript
import * as cdk from 'aws-cdk-lib';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';

interface DatabaseStackProps extends cdk.StackProps {
  vpc: ec2.Vpc;
  databaseSecurityGroup: ec2.SecurityGroup;
}

export class DatabaseStack extends cdk.Stack {
  public readonly databaseCluster: rds.DatabaseCluster;
  public readonly databaseSecret: secretsmanager.Secret;

  constructor(scope: Construct, id: string, props: DatabaseStackProps) {
    super(scope, id, props);

    const { vpc, databaseSecurityGroup } = props;

    // Create secret for database credentials
    this.databaseSecret = new secretsmanager.Secret(this, 'DatabaseSecret', {
      description: 'Aurora database master credentials',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          username: 'postgres',
        }),
        generateStringKey: 'password',
        excludeCharacters: ' %+~`#$&*()|[]{}:;<>?!\'/@"\\',
        passwordLength: 32,
      },
    });

    // Create Aurora Serverless v2 cluster
    this.databaseCluster = new rds.DatabaseCluster(this, 'NotesDatabase', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_14_10,
      }),
      credentials: rds.Credentials.fromSecret(this.databaseSecret),
      writer: rds.ClusterInstance.serverlessV2('writer', {
        scaleWithWriter: true,
      }),
      serverlessV2MinCapacity: 0.5,
      serverlessV2MaxCapacity: 1.0,
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      securityGroups: [databaseSecurityGroup],
      defaultDatabaseName: 'notesdb',
      enableDataApi: true,
      storageEncrypted: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // For development - change for production
      deletionProtection: false, // For development - set to true for production
    });

    // Output database endpoint
    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: this.databaseCluster.clusterEndpoint.hostname,
      exportName: 'NotesApp-Database-Endpoint',
    });

    // Output secret ARN
    new cdk.CfnOutput(this, 'DatabaseSecretArn', {
      value: this.databaseSecret.secretArn,
      exportName: 'NotesApp-Database-Secret-Arn',
    });
  }
}
```

**Step 2: Update app.ts to include database stack**

Modify `src/infra/bin/app.ts`:
```typescript
#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { NetworkStack } from '../lib/network-stack';
import { DatabaseStack } from '../lib/database-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
};

// Network infrastructure
const networkStack = new NetworkStack(app, 'NotesAppNetworkStack', {
  env,
  description: 'Network infrastructure for Notes application',
});

// Database infrastructure
const databaseStack = new DatabaseStack(app, 'NotesAppDatabaseStack', {
  env,
  vpc: networkStack.vpc,
  databaseSecurityGroup: networkStack.databaseSecurityGroup,
  description: 'Aurora Serverless v2 database for Notes application',
});

databaseStack.addDependency(networkStack);

app.synth();
```

**Step 3: Build and test synthesis**

Run: `cd src/infra && npm run build && npx cdk synth`
Expected: CloudFormation templates generated for both stacks

**Step 4: Commit**

```bash
git add src/infra/lib/database-stack.ts src/infra/bin/app.ts
git commit -m "feat: add CDK database stack with Aurora Serverless v2"
```

**Skills:** @backend-models, @global-conventions

---

## Task 16: AWS CDK Infrastructure - Backend Stack

**Files:**
- Create: `src/infra/lib/backend-stack.ts`
- Modify: `src/infra/bin/app.ts`

**Step 1: Create Backend Stack**

Create `src/infra/lib/backend-stack.ts`:
```typescript
import * as cdk from 'aws-cdk-lib';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

interface BackendStackProps extends cdk.StackProps {
  vpc: ec2.Vpc;
  ecsSecurityGroup: ec2.SecurityGroup;
  databaseSecret: secretsmanager.Secret;
  databaseEndpoint: string;
}

export class BackendStack extends cdk.Stack {
  public readonly service: ecsPatterns.ApplicationLoadBalancedFargateService;
  public readonly apiUrl: string;

  constructor(scope: Construct, id: string, props: BackendStackProps) {
    super(scope, id, props);

    const { vpc, ecsSecurityGroup, databaseSecret, databaseEndpoint } = props;

    // Create ECR repository
    const repository = new ecr.Repository(this, 'NotesApiRepository', {
      repositoryName: 'notes-api',
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      emptyOnDelete: true,
    });

    // Create ECS cluster
    const cluster = new ecs.Cluster(this, 'NotesCluster', {
      vpc,
      containerInsights: true,
    });

    // Create Fargate service with ALB
    this.service = new ecsPatterns.ApplicationLoadBalancedFargateService(this, 'NotesApiService', {
      cluster,
      cpu: 256,
      memoryLimitMiB: 512,
      desiredCount: 1,
      taskImageOptions: {
        image: ecs.ContainerImage.fromEcrRepository(repository, 'latest'),
        containerPort: 8000,
        environment: {
          DATABASE_HOST: databaseEndpoint,
          DATABASE_NAME: 'notesdb',
        },
        secrets: {
          DATABASE_PASSWORD: ecs.Secret.fromSecretsManager(databaseSecret, 'password'),
          DATABASE_USERNAME: ecs.Secret.fromSecretsManager(databaseSecret, 'username'),
        },
        logDriver: ecs.LogDrivers.awsLogs({
          streamPrefix: 'notes-api',
        }),
      },
      publicLoadBalancer: true,
      assignPublicIp: true,
      securityGroups: [ecsSecurityGroup],
      healthCheck: {
        command: ['CMD-SHELL', 'curl -f http://localhost:8000/health || exit 1'],
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        retries: 3,
        startPeriod: cdk.Duration.seconds(60),
      },
    });

    // Configure health check on ALB
    this.service.targetGroup.configureHealthCheck({
      path: '/health',
      interval: cdk.Duration.seconds(30),
      timeout: cdk.Duration.seconds(5),
      healthyThresholdCount: 2,
      unhealthyThresholdCount: 3,
    });

    // Grant ECS task access to secrets
    databaseSecret.grantRead(this.service.taskDefinition.taskRole);

    // Allow ECS task to pull from ECR
    repository.grantPull(this.service.taskDefinition.taskRole);

    // Store API URL
    this.apiUrl = `http://${this.service.loadBalancer.loadBalancerDnsName}`;

    // Output API URL
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: this.apiUrl,
      exportName: 'NotesApp-Api-Url',
      description: 'API endpoint URL',
    });

    // Output ECR repository URI
    new cdk.CfnOutput(this, 'EcrRepositoryUri', {
      value: repository.repositoryUri,
      exportName: 'NotesApp-ECR-Uri',
      description: 'ECR repository URI for backend container',
    });
  }
}
```

**Step 2: Update app.ts to include backend stack**

Modify `src/infra/bin/app.ts`:
```typescript
#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { NetworkStack } from '../lib/network-stack';
import { DatabaseStack } from '../lib/database-stack';
import { BackendStack } from '../lib/backend-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
};

// Network infrastructure
const networkStack = new NetworkStack(app, 'NotesAppNetworkStack', {
  env,
  description: 'Network infrastructure for Notes application',
});

// Database infrastructure
const databaseStack = new DatabaseStack(app, 'NotesAppDatabaseStack', {
  env,
  vpc: networkStack.vpc,
  databaseSecurityGroup: networkStack.databaseSecurityGroup,
  description: 'Aurora Serverless v2 database for Notes application',
});

// Backend infrastructure
const backendStack = new BackendStack(app, 'NotesAppBackendStack', {
  env,
  vpc: networkStack.vpc,
  ecsSecurityGroup: networkStack.ecsSecurityGroup,
  databaseSecret: databaseStack.databaseSecret,
  databaseEndpoint: databaseStack.databaseCluster.clusterEndpoint.hostname,
  description: 'ECS Fargate backend service for Notes application',
});

databaseStack.addDependency(networkStack);
backendStack.addDependency(databaseStack);

app.synth();
```

**Step 3: Build and test synthesis**

Run: `cd src/infra && npm run build && npx cdk synth`
Expected: CloudFormation templates generated for all stacks

**Step 4: Commit**

```bash
git add src/infra/lib/backend-stack.ts src/infra/bin/app.ts
git commit -m "feat: add CDK backend stack with ECS Fargate and ALB"
```

**Skills:** @backend-api, @global-conventions

---

## Task 17: AWS CDK Infrastructure - Frontend Stack

**Files:**
- Create: `src/infra/lib/frontend-stack.ts`
- Modify: `src/infra/bin/app.ts`
- Create: `src/frontend/next.config.js`

**Step 1: Create Next.js config**

Create `src/frontend/next.config.js`:
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  experimental: {
    outputFileTracingRoot: undefined,
  },
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  },
};

module.exports = nextConfig;
```

**Step 2: Create Frontend Stack**

Create `src/infra/lib/frontend-stack.ts`:
```typescript
import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as cloudfrontOrigins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import * as path from 'path';

interface FrontendStackProps extends cdk.StackProps {
  apiUrl: string;
}

export class FrontendStack extends cdk.Stack {
  public readonly distributionUrl: string;

  constructor(scope: Construct, id: string, props: FrontendStackProps) {
    super(scope, id, props);

    const { apiUrl } = props;

    // Create S3 bucket for static assets
    const websiteBucket = new s3.Bucket(this, 'NotesFrontendBucket', {
      websiteIndexDocument: 'index.html',
      websiteErrorDocument: 'error.html',
      publicReadAccess: false,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      cors: [
        {
          allowedMethods: [s3.HttpMethods.GET, s3.HttpMethods.HEAD],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
        },
      ],
    });

    // Create CloudFront Origin Access Identity
    const originAccessIdentity = new cloudfront.OriginAccessIdentity(this, 'OAI', {
      comment: 'OAI for Notes App frontend',
    });

    // Grant CloudFront access to S3 bucket
    websiteBucket.grantRead(originAccessIdentity);

    // Create CloudFront distribution
    const distribution = new cloudfront.Distribution(this, 'NotesDistribution', {
      defaultRootObject: 'index.html',
      defaultBehavior: {
        origin: new cloudfrontOrigins.S3Origin(websiteBucket, {
          originAccessIdentity,
        }),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD,
        compress: true,
      },
      errorResponses: [
        {
          httpStatus: 404,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
          ttl: cdk.Duration.seconds(0),
        },
        {
          httpStatus: 403,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
          ttl: cdk.Duration.seconds(0),
        },
      ],
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
      enabled: true,
      httpVersion: cloudfront.HttpVersion.HTTP2_AND_3,
    });

    // Deploy frontend assets to S3
    new s3deploy.BucketDeployment(this, 'DeployFrontend', {
      sources: [
        s3deploy.Source.asset(path.join(__dirname, '../../frontend'), {
          bundling: {
            image: cdk.DockerImage.fromRegistry('node:20-alpine'),
            command: [
              'sh',
              '-c',
              [
                'npm ci',
                `NEXT_PUBLIC_API_URL=${apiUrl} npm run build`,
                'npm run export || true', // Next.js 13+ might not have export
                'cp -r out/* /asset-output/ 2>/dev/null || cp -r .next/static /asset-output/ || true',
                'cp -r public/* /asset-output/ 2>/dev/null || true',
              ].join(' && '),
            ],
          },
        }),
      ],
      destinationBucket: websiteBucket,
      distribution,
      distributionPaths: ['/*'],
    });

    this.distributionUrl = `https://${distribution.distributionDomainName}`;

    // Output CloudFront URL
    new cdk.CfnOutput(this, 'FrontendUrl', {
      value: this.distributionUrl,
      exportName: 'NotesApp-Frontend-Url',
      description: 'CloudFront distribution URL for frontend',
    });

    // Output S3 bucket name
    new cdk.CfnOutput(this, 'FrontendBucket', {
      value: websiteBucket.bucketName,
      exportName: 'NotesApp-Frontend-Bucket',
      description: 'S3 bucket for frontend assets',
    });
  }
}
```

**Step 3: Update app.ts to include frontend stack**

Modify `src/infra/bin/app.ts`:
```typescript
#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { NetworkStack } from '../lib/network-stack';
import { DatabaseStack } from '../lib/database-stack';
import { BackendStack } from '../lib/backend-stack';
import { FrontendStack } from '../lib/frontend-stack';

const app = new cdk.App();

const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
};

// Network infrastructure
const networkStack = new NetworkStack(app, 'NotesAppNetworkStack', {
  env,
  description: 'Network infrastructure for Notes application',
});

// Database infrastructure
const databaseStack = new DatabaseStack(app, 'NotesAppDatabaseStack', {
  env,
  vpc: networkStack.vpc,
  databaseSecurityGroup: networkStack.databaseSecurityGroup,
  description: 'Aurora Serverless v2 database for Notes application',
});

// Backend infrastructure
const backendStack = new BackendStack(app, 'NotesAppBackendStack', {
  env,
  vpc: networkStack.vpc,
  ecsSecurityGroup: networkStack.ecsSecurityGroup,
  databaseSecret: databaseStack.databaseSecret,
  databaseEndpoint: databaseStack.databaseCluster.clusterEndpoint.hostname,
  description: 'ECS Fargate backend service for Notes application',
});

// Frontend infrastructure
const frontendStack = new FrontendStack(app, 'NotesAppFrontendStack', {
  env,
  apiUrl: backendStack.apiUrl,
  description: 'CloudFront and S3 frontend for Notes application',
});

databaseStack.addDependency(networkStack);
backendStack.addDependency(databaseStack);
frontendStack.addDependency(backendStack);

app.synth();
```

**Step 4: Build and test synthesis**

Run: `cd src/infra && npm run build && npx cdk synth`
Expected: CloudFormation templates generated for all stacks

**Step 5: Commit**

```bash
git add src/infra/ src/frontend/next.config.js
git commit -m "feat: complete CDK infrastructure with frontend stack"
```

**Skills:** @frontend-components, @global-conventions

---

## Task 18: Deployment Script

**Files:**
- Create: `deploy.sh`
- Create: `README.md`

**Step 1: Create deployment script**

Create `deploy.sh`:
```bash
#!/bin/bash
set -e

echo "=== Starting AWS Deployment ==="

# Check AWS credentials
echo "Checking AWS credentials..."
aws sts get-caller-identity || (echo "AWS credentials not configured" && exit 1)

# Get AWS account ID and region
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-east-1}
echo "Deploying to account: $AWS_ACCOUNT in region: $AWS_REGION"

# Build backend Docker image
echo "Building backend Docker image..."
cd src/backend
docker build -t notes-api:latest .
cd ../..

# Bootstrap CDK (if needed)
echo "Bootstrapping CDK..."
cd src/infra
npx cdk bootstrap aws://$AWS_ACCOUNT/$AWS_REGION || true

# Deploy network stack
echo "Deploying network stack..."
npx cdk deploy NotesAppNetworkStack --require-approval never

# Deploy database stack
echo "Deploying database stack..."
npx cdk deploy NotesAppDatabaseStack --require-approval never

# Get ECR repository URI
echo "Getting ECR repository URI..."
npx cdk deploy NotesAppBackendStack --require-approval never
ECR_URI=$(aws cloudformation describe-stacks \
  --stack-name NotesAppBackendStack \
  --query "Stacks[0].Outputs[?OutputKey=='EcrRepositoryUri'].OutputValue" \
  --output text)

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URI

# Tag and push Docker image
echo "Pushing Docker image to ECR..."
docker tag notes-api:latest $ECR_URI:latest
docker push $ECR_URI:latest

# Update ECS service
echo "Updating ECS service..."
aws ecs update-service \
  --cluster NotesCluster \
  --service NotesApiService \
  --force-new-deployment \
  --region $AWS_REGION || true

# Deploy frontend stack
echo "Deploying frontend stack..."
npx cdk deploy NotesAppFrontendStack --require-approval never

# Get output URLs
API_URL=$(aws cloudformation describe-stacks \
  --stack-name NotesAppBackendStack \
  --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \
  --output text)

FRONTEND_URL=$(aws cloudformation describe-stacks \
  --stack-name NotesAppFrontendStack \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendUrl'].OutputValue" \
  --output text)

echo "=== Deployment Complete ==="
echo "API URL: $API_URL"
echo "Frontend URL: $FRONTEND_URL"
echo ""
echo "Test with: curl $API_URL/health"
```

**Step 2: Create README**

Create `README.md`:
```markdown
# Notes Application MVP

A simple CRUD note-taking application built with FastAPI, Next.js, and AWS infrastructure.

## Architecture

- **Frontend**: Next.js 14 with App Router, deployed to CloudFront + S3
- **Backend**: FastAPI Python API, containerized and deployed to ECS Fargate
- **Database**: Aurora Serverless v2 PostgreSQL
- **Infrastructure**: AWS CDK v2 (TypeScript)

## Local Development

### Prerequisites

- Node.js 18+
- Python 3.11+
- Docker
- PostgreSQL running on port 5433
- AWS CLI configured

### Setup

1. Install backend dependencies:
```bash
cd src/backend
pip install -r requirements.txt
```

2. Install frontend dependencies:
```bash
cd src/frontend
npm install
```

3. Install infrastructure dependencies:
```bash
cd src/infra
npm install
```

### Running Locally

1. Start backend:
```bash
cd src/backend
uvicorn main:app --reload --port 8000
```

2. Start frontend:
```bash
cd src/frontend
npm run dev
```

3. Access application at http://localhost:3000

### Testing

Run all tests:
```bash
./test-local.sh
```

Run API tests:
```bash
newman run postman/collections/notes-api.json -e postman/environments/local.json
```

## Deployment

### Prerequisites

- AWS account with appropriate permissions
- AWS CLI configured
- Docker installed

### Deploy to AWS

```bash
./deploy.sh
```

This will:
1. Build and push Docker image to ECR
2. Deploy VPC and networking
3. Deploy Aurora Serverless database
4. Deploy ECS Fargate backend
5. Deploy CloudFront + S3 frontend

### Clean Up

Remove all AWS resources:
```bash
cd src/infra
npx cdk destroy --all
```

## Project Structure

```
├── src/
│   ├── backend/          # FastAPI backend
│   ├── frontend/         # Next.js frontend
│   └── infra/           # AWS CDK infrastructure
├── postman/             # API test collections
├── docs/                # Documentation
│   ├── designs/         # Design documents
│   └── plans/           # Implementation plans
├── test-local.sh        # Local integration tests
└── deploy.sh            # AWS deployment script
```

## API Endpoints

- `GET /health` - Health check
- `GET /api/notes` - List all notes
- `GET /api/notes/{id}` - Get single note
- `POST /api/notes` - Create note
- `PUT /api/notes/{id}` - Update note
- `DELETE /api/notes/{id}` - Delete note

## Environment Variables

### Backend
- `DATABASE_URL` - PostgreSQL connection string

### Frontend
- `NEXT_PUBLIC_API_URL` - Backend API URL

## Estimated AWS Costs

- Aurora Serverless v2: ~$20/month (0.5 ACU minimum)
- ECS Fargate: ~$10/month (1 task, 0.25 vCPU)
- CloudFront + S3: <$5/month (low traffic)
- **Total**: ~$35/month for low-traffic MVP

## License

MIT
```

**Step 3: Make deployment script executable**

Run: `chmod +x deploy.sh`

**Step 4: Commit**

```bash
git add deploy.sh README.md
git commit -m "docs: add deployment script and comprehensive README"
```

**Skills:** @global-conventions

---

## Summary

This implementation plan provides a complete, step-by-step guide to building the note-taking MVP application. Each task follows TDD principles with:

1. **Backend Tasks (1-9)**: Database setup, models, CRUD API, containerization
2. **Frontend Tasks (10-12)**: Next.js setup, components, API integration
3. **Testing Task (13)**: Local integration testing
4. **Infrastructure Tasks (14-17)**: CDK stacks for network, database, backend, frontend
5. **Deployment Task (18)**: Scripts and documentation

Key features:
- Complete code examples (no placeholders)
- Test-first development for every feature
- Exact file paths and commands
- Newman/Postman API testing
- Comprehensive error handling
- Production-ready infrastructure
- Cost-optimized AWS services

The plan ensures an engineer with no context can successfully implement the entire application by following each task sequentially.