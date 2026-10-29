# Python Style Guide

## Language Version

**Python 3.11+** — Use modern Python features including:
- Type union syntax: `str | None` instead of `Optional[str]`
- `from __future__ import annotations` for forward references
- Structural pattern matching where appropriate

---

## Naming Convention: RPN (Reverse Polish Notation) Style

Functions and methods follow a **noun_verb** pattern, placing the subject before the action.

### Pattern

```text
<subject>[descriptor]_<action>[modifier]
```

### Examples

**Standard Python (verb-noun):**
```python
def get_user_names() -> list[str]: ...
def is_login_valid() -> bool: ...
def parse_user_data(raw: str) -> UserData: ...
```

**RPN (noun-verb):**
```python
def userNames_get() -> list[str]: ...
def login_isValidCheck() -> bool: ...
def dataFromUser_parse(raw: str) -> UserData: ...
```

### Additional Examples

```python
def configuration_load(path: Path) -> ApplicationConfig:
    """Load application configuration from a file."""
    ...

def document_validate(document: Document) -> ValidationResult:
    """Validate a document before storage."""
    ...

def sessionID_generate(title: str = "") -> str:
    """Generate a unique session identifier with an optional title."""
    ...
```

### Rationale

- **Subject-first thinking:** Makes it clear *what* is being operated on
- **Grouping:** Related operations on the same subject cluster together alphabetically
- **Searchability:** Easy to find all operations on a subject (e.g., search for `document.*_`)

---

## Type Hints: Pervasive and Explicit

**Every function, method, and variable** that isn't trivially obvious must have type hints.

### Function Signatures

```python
# ✓ GOOD: Complete type hints
def document_validate(document: Document, strict: bool) -> ValidationResult:
    ...

# ✗ BAD: Missing return type
def document_validate(document: Document, strict: bool):
    ...
```

### Local Variables

Type hints on local variables when the type isn't obvious from initialization:

```python
# ✓ GOOD: Clear from initialization
retry_count = 0

# ✓ GOOD: Type hint clarifies intent
documents_by_id: dict[str, Document] = {}

# ✗ BAD: Type unclear
result = {}  # What type is this?
```

### Collections

Be specific about collection contents:

```python
# ✓ GOOD
def userNames_get() -> list[str]: ...
def documents_get() -> dict[str, Document]: ...

# ✗ BAD: Generic types hide information
def userNames_get() -> list: ...
def documents_get() -> dict: ...
```

---

## Return Types: Models for Non-Primitives

**Any non-primitive return type should be a defined model class.** Collections of primitives or defined models should declare their element types.

### Use dataclass or BaseModel

**dataclass** — Default choice for pure data structures:
```python
from dataclasses import dataclass

@dataclass
class ValidationResult:
    valid: bool
    errors: list[str]
```

**BaseModel (Pydantic)** — When validation is needed; use **BaseSettings** for environment variable injection:
```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class DatabaseConfig(BaseSettings):
    """Configuration that can load from DB_HOST and DB_PORT."""

    host: str = "localhost"
    port: int = 27017

    model_config = SettingsConfigDict(env_prefix="DB_", env_file=".env")
```

### When to Use Each

| Use Case | Model Type | Rationale |
|----------|-----------|-----------|
| Pure data structure | `dataclass` | Simpler, native Python, no dependencies |
| Config from env vars | `BaseSettings` (Pydantic) | Automatic environment variable binding |
| API request/response | `BaseModel` (Pydantic) | Validation and serialization |
| Complex validation | `BaseModel` (Pydantic) | Field validators and constraints |

### Examples

```python
# ✓ GOOD: Defined model
@dataclass
class UserSummary:
    username: str
    email: str

def users_get() -> list[UserSummary]:
    ...

# ✗ BAD: Returns unstructured dict
def users_get() -> list[dict[str, Any]]:
    ...
```

---

## Method Length: Contextual Refactoring

No hard line limit. Refactor based on **multiple factors**:

### Primary Signals

1. **Nesting depth** — More than 3 levels suggests extraction
2. **Responsibility count** — Method doing >1 conceptual task
3. **Readability** — Can you explain it in one sentence?
4. **Repetition** — Same logic appearing multiple times

### Example: Good Length with Clarity

```python
def documents_validate(documents: Iterable[Document]) -> ValidationResult:
    """Collect validation errors across a batch of documents."""
    errors: list[str] = []

    for document in documents:
        result: ValidationResult = document_validate(document, strict=True)
        for error in result.errors:
            errors.append(f"{document.id}: {error}")

    return ValidationResult(valid=not errors, errors=errors)
```

**Why this structure is acceptable:**
- Single clear responsibility: orchestrate batch validation
- Individual document validation delegated to a focused helper
- Simple flow, no deep nesting
- Well-named variables make intent clear

### When to Extract

```python
# ✗ BAD: Too much nesting and multiple concerns
def config_process(raw_config: dict[str, Any]) -> ProcessedConfig:
    if "database" in raw_config:
        db = raw_config["database"]
        if "host" in db:
            if db["host"].startswith("postgres://"):
                # Parse connection string
                parts = db["host"].split("://")[1].split(":")
                if len(parts) == 2:
                    host, port = parts[0], int(parts[1])
                    # Validate port range
                    if 1024 <= port <= 65535:
                        ...
```

**Should become:**
```python
def config_process(raw_config: dict[str, Any]) -> ProcessedConfig:
    """Process raw configuration into validated config object."""
    db_config: DatabaseRaw = databaseConfig_extract(raw_config)
    db_validated: DatabaseValidated = databaseConfig_validate(db_config)
    return ProcessedConfig(database=db_validated)

def databaseConfig_extract(raw_config: dict[str, Any]) -> DatabaseRaw:
    """Extract database configuration section."""
    ...

def databaseConfig_validate(config: DatabaseRaw) -> DatabaseValidated:
    """Validate database configuration parameters."""
    ...
```

---

## Code Structure Principles

### 1. Explicit Over Implicit

```python
# ✓ GOOD: Clear intent and units
milliseconds_per_second: int = 1_000
timeout_seconds: float = timeout_milliseconds / milliseconds_per_second

# ✗ BAD: Names and conversion obscure intent
t = value / 1e3
```

### 2. One Source of Truth

```python
# ✓ GOOD: Configuration drives behavior
config: ApplicationConfig = ...
timeout_seconds: int = config.request_timeout

# ✗ BAD: Hardcoded values
timeout_seconds = 30  # Duplicates the configured timeout
```

### 3. Type Safety Over Flexibility

```python
# ✓ GOOD: Specific types
def results_merge(
    base: ValidationResult,
    overlay: ValidationResult,
) -> ValidationResult:
    ...

# ✗ BAD: Overly generic
def results_merge(base: Any, overlay: Any) -> Any:
    ...
```

---

## Import Organization

```python
"""Module docstring."""
from __future__ import annotations  # Before other imports

# Standard library
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterable

# Third-party
from pydantic import BaseModel

# Local
from app.models.dataModel import DocumentData
from app.utils.session import sessionID_generate
```

---

## Documentation

**Documentation Standard: Google-style docstrings**

All Python code uses Google-style docstrings with explicit Args, Returns, Raises, and Attributes sections where applicable. Every module, class, and function must be documented. Short examples elsewhere in this guide abbreviate docstrings to focus on the convention being illustrated.

### Module-Level Docstrings

**Every module** must have a comprehensive module-level docstring explaining:
- Purpose and scope
- Key classes/functions provided
- Usage examples (if applicable)
- Dependencies or assumptions

```python
"""Document validation utilities.

This module validates individual documents and collects validation errors across
batches. It reports errors without changing the input documents.

Key components:
    - ValidationResult: Container for validation status and error messages
    - document_validate: Validate one document
    - documents_validate: Collect errors across a batch

Typical usage:
    result = document_validate(document, strict=True)
    if not result.valid:
        print(result.errors)

Dependencies:
    - Requires the application's Document model
    - Validation operates on already parsed documents
"""
from __future__ import annotations
...
```

### Function/Method Docstrings

Use **explicit Google-style docstrings** with complete parameter and return documentation:

```python
def sessionID_generate(title: str = "") -> str:
    """Generate a unique session identifier with an optional title.

    Combines a timestamp and UUID to distinguish sessions. Appends the title
    when supplied so callers can recognize the session's purpose.

    Args:
        title: Optional descriptive suffix. An empty string omits the suffix.

    Returns:
        Session identifier in YYYYMMDDHHmmSSmmm-<uuid>[-<title>] format.

    Example:
        >>> session_id = sessionID_generate("import")
        >>> session_id.endswith("-import")
        True
    """
    ...
```

### Complex Docstring Examples

**Structured return values:**
```python
def documents_validate(documents: Iterable[Document]) -> ValidationResult:
    """Validate a batch of documents and collect all errors.

    Applies strict validation to each document and prefixes errors with the
    document identifier so callers can locate the affected input.

    Args:
        documents: Parsed documents to validate. The iterable is consumed once.

    Returns:
        ValidationResult with valid=True when no errors were found. Its errors
        field contains messages prefixed with the corresponding document ID.

    Example:
        >>> result = documents_validate([])
        >>> result.valid
        True
        >>> result.errors
        []
    """
    ...
```

**With raised exceptions:**
```python
def configuration_load(path: Path) -> ApplicationConfig:
    """Load application configuration from a JSON file.

    Parses the file and validates its contents against the application
    configuration model.

    Args:
        path: Path to an existing UTF-8 JSON configuration file.

    Returns:
        ApplicationConfig containing the validated configuration values.

    Raises:
        FileNotFoundError: If the specified path does not exist.
        json.JSONDecodeError: If the file contains invalid JSON syntax.
        pydantic.ValidationError: If configuration fields fail validation.

    Example:
        >>> config = configuration_load(Path("config.json"))
        >>> timeout = config.request_timeout
    """
    ...
```

**Class/dataclass documentation:**
```python
@dataclass
class ValidationResult:
    """Container for document validation output.

    Allows callers to inspect overall validity and report individual errors
    without parsing an unstructured response.

    Attributes:
        valid: Whether validation completed without errors.
        errors: Human-readable validation errors. Empty for a valid result.

    Example:
        >>> result = ValidationResult(valid=True, errors=[])
        >>> result.valid
        True
    """

    valid: bool
    errors: list[str]
```

### Comments

Use sparingly—prefer clear naming. Comments explain **why** unusual decisions were made:

```python
# Keep the suffix so operators can identify sessions in diagnostic logs.
if title:
    session_id += f"-{title}"
```

---

## Summary Checklist

- [ ] Python 3.11+ features used where appropriate
- [ ] All functions use RPN naming: `subject_action` pattern
- [ ] Pervasive type hints on parameters, returns, and non-obvious variables
- [ ] Non-primitive returns use `dataclass` or `BaseModel`; environment configuration uses `BaseSettings`
- [ ] Methods refactored based on nesting depth, responsibility count, and clarity—not arbitrary line limits
- [ ] Explicit variable names with clear intent
- [ ] One source of truth (config-driven, not hardcoded)
- [ ] Type-safe interfaces preferred over flexible/generic types
- [ ] Imports organized: future, stdlib, third-party, local
- [ ] **Every module has comprehensive module-level docstring** (purpose, key components, usage, dependencies)
- [ ] **Every function/method has complete Google-style docstring:**
  - [ ] Short description of what it does
  - [ ] Args section with each parameter explained (type, purpose, constraints)
  - [ ] Returns section explaining return value structure and meaning
  - [ ] Raises section if exceptions can be raised
  - [ ] Example showing typical usage (when helpful)
- [ ] **Every class/dataclass has docstring with:**
  - [ ] Purpose and use case
  - [ ] Attributes section explaining each field
  - [ ] Example showing construction and usage
- [ ] Comments used sparingly to explain unusual decisions (not what code does)
