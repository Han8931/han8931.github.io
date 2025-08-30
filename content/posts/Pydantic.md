
---
weight: 1
title: Clean Validation with Pydantic v2
date: 2025-08-30
draft: false
author: Han
description: A tutorial for Pydantic
tags: ["Python", "Pydantic", "config", "environment variables", "mongodb"]
categories: ["Python", "Pydantic"]
---

> 📝 **Update** (2025-08): This post was originally published in **April 2024** and has been updated to reflect changes in **Pydantic v2**, including the new *field validator*, *model validator*, and *Annotated*-based validation patterns. Also, this post now includes a **new section on using Pydantic with MongoDB**. 

Python's dynamic typing system is indeed convenient, allowing you to create variables without explicitly declaring their types. While this flexibility can streamline development, it can also introduce unexpected behavior, particularly when handling data from external sources like APIs or user input.

Python's dynamic typing system is indeed convenient, allowing you to create variables without explicitly declaring their types. While this flexibility can streamline development, it can also introduce unexpected behavior, particularly when handling data from external sources like APIs or user input.

Consider the following scenario:
```python
employee = Employee("Han", 30) # Correct
employee = Employee("Moon", "30") # Correct
```
- Here, the second argument is intended to represent an age, typically an integer. However, in the second example, it's a string, potentially leading to errors or unexpected behavior down the line.

To address such issues, Pydantic offers a solution through data validation. Pydantic is a library specifically designed for this purpose, ensuring that the data conforms to pre-defined schemas.

The primary method of defining schemas in Pydantic is through models. Models are essentially classes that inherit from `pydantic.BaseModel` and define fields with annotated attributes. You can think of models as similar to structs in languages like C.

While Pydantic models share similarities with Python's dataclasses, they are preferred when data validation is essential. Pydantic models guarantee that the fields of an instance will adhere to specified types, providing both runtime validation and serving as type hints during development.

Let's illustrate this with a simple example:
```python
from pydantic import BaseModel

class User(BaseModel):
	id: int
	name: str = "John Doe"
```
- `User` model has two fields: `id` integer and `name` string, which has a default value. 
-  You can create an instance, `user = User(id="123")`

You can also define models that include other models, allowing for complex data structures:
```python
from pydantic import BaseModel
from typing import List  

class Item(BaseModel):     
	name: str     
	price: float  

class Order(BaseModel):     
	items: List[Item]     
	total_price: float  

order = Order(
        items=[{"name": "Burger", "price": 5.99}, {"name": "Fries", "price": 2.99}], 
        total_price=8.98
    )  
print(order)
```


## Field

In **Pydantic**, the `Field()` function is used to **provide extra metadata and control over how a field behaves** — beyond just its type. It is especially useful for:

* Setting **default values**
* Adding **aliases** (e.g., mapping from external keys like `_id`)
* Adding **validation constraints** (e.g., min/max length, regex)
* Documenting fields (for use in OpenAPI docs, etc.)

For example,
```python
from pydantic import BaseModel, Field

class User(BaseModel):
    name: str = Field(..., description="The full name of the user")
    age: int = Field(default=0, ge=0, lt=150) # Set a default value
```

You can test it 
```python
class Product(BaseModel):
    name: str = Field(..., min_length=3, max_length=50)
    price: float = Field(..., gt=0)

prod = Product(name="test", price=-10)  

# price
#   Input should be greater than 0 [type=greater_than, input_value=-10, input_type=int]
```

Field with an Alias (e.g., for MongoDB `_id`):
```python
class User(BaseModel):
    id: str = Field(..., alias="_id")
```
Now Pydantic will accept both:
```python
User(id="abc")             # native style
User(**{"_id": "abc"})     # MongoDB style ✅
```

When you dump it back, you can choose which name to use:
```python
user = User(id="abc")
print(user.model_dump())                 # {'id': 'abc'}
print(user.model_dump(by_alias=True))    # {'_id': 'abc'}
```

Sometimes a field needs a dynamic value at runtime like:
- UUID
- Timestamp

You can't use `default=...` because it would be evaluated once at class definition time, not per instance. So, we use `default_factory`. Now every time you create an instance:
```python
from datetime import datetime

class Event(BaseModel):
    id: str = Field(default_factory=lambda: "evt_" + datetime.utcnow().isoformat())

event1 = Event()
event2 = Event()
```
You'll get unique ids like:
```python
print(event1.id)  # evt-2025-08-30T11:28:01.123456
print(event2.id)  # evt-2025-08-30T11:28:03.987654
```

## Validators

Pydantic provides validators, which enables you to impose custom validation rules on model fields. These validators extend beyond simple type validation and allow you to enforce additional checks. 

### Field validators
a field validator is a callable taking the value to be validated as an argument and returning the validated value. Here's a simple example:

```python
from typing import Annotated
from pydantic import BaseModel, AfterValidator, BaseModel, ValidationError

def check_age(value):
    if value < 18:
        raise ValueError('Age must be at least 18')
    return value

class Person(BaseModel):
    name: str
    age: Annotated[int, AfterValidator(check_age)]

# This will raise an error because the age is below 18
try:
    Person(name="Charlie", age=17)
except ValidationError as e:
    print(e)
```
This uses Python’s typing.Annotated type to attach validation logic to a field in a declarative way.
- `int`: The field type (`age` is an integer).
- `AfterValidator(check_age)`: Runs `check_age(value)` after Pydantic has validated and parsed the raw value (e.g., converting string to int if needed).
AfterValidator ensures your custom validator runs after type coercion and default validation.

You can use a single validator function to apply the same logic (e.g., capitalization, stripping, type conversion, etc.) to multiple fields by using the decorator pattern.
```
from pydantic import BaseModel, field_validator

class User(BaseModel):
    first_name: str
    last_name: str

    @field_validator('first_name', 'last_name', mode='before')
    @classmethod
    def capitalize_names(cls, value: str) -> str:
        return value.capitalize()

user = User(first_name="alice", last_name="cooper")
print(user.first_name)  # Alice
print(user.last_name)   # Cooper
```

### Model Validators

The `@model_validator` is a new feature in Pydantic v2 that replaces the older `@root_validator` from v1.

It lets you **validate the entire model at once** — useful when:
- Fields depend on each other (e.g., confirm passwords match)
- You want to enforce cross-field consistency
- You want to do post-processing after all fields are parsed

```python
from typing_extensions import Self
from pydantic import BaseModel, model_validator

class UserModel(BaseModel):
    username: str
    password: str
    password_repeat: str

    @model_validator(mode='after')
    def check_passwords_match(self) -> Self:
        if self.password != self.password_repeat:
            raise ValueError('Passwords do not match')
        return self

try:
    user = UserModel(username="alice", password="secret", password_repeat="notsecret")
except ValueError as e:
    print(f"Validation failed: {e}")


# Validation failed: 1 validation error for UserModel
#   Passwords do not match (type=value_error)
```
- `@model_validator(mode='after')` runs **after all field-level validation is complete**
- Runs on the **model instance** (`self`, `UserModel` in this case) instead of just individual fields
- You can access any field via `self.fieldname`
- You must return `self`, or raise `ValueError` if validation fails

## When to Use Each Type of Validator

| Validator                   | Purpose                                                   | Scope       | Return Value      |
| --------------------------- | --------------------------------------------------------- | ----------- | ----------------- |
| `@field_validator`          | Validate one or more **individual fields**                | Field-level | Transformed value |
| `@model_validator` (after)  | Validate the **entire model**                             | Model-level | Return `self`     |
| `@model_validator` (before) | Preprocess the **input dict** before any field validation | Dict-level  | Return a dict     |

---

## Pydantic for Configuration Management

Pydantic isn't just for validating user input — it's also an excellent tool for managing application settings through environment variables or `.env` files. This is especially useful for 12-factor apps that rely on external configuration across environments.

To use this feature in **Pydantic v2**, install the standalone `pydantic-settings` package:
```
pip install pydantic-settings
```

Then, for example
```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class DatabaseSettings(BaseSettings):
    api_key: str
    database_password: str

    model_config = SettingsConfigDict(env_file=".env")  # loads from .env by default

settings = DatabaseSettings()
print(settings.api_key)
print(settings.database_password)
```
This automatically reads values from environment variables or a `.env` file (if present), making it ideal for managing sensitive or environment-specific values.

### Pydantic SecretStr
Pydantic provides special types like `SecretStr` to handle sensitive information, such as passwords or API keys. These ensure that secrets are not accidentally printed or logged:

```python
from pydantic import BaseModel, SecretStr

class User(BaseModel):
    username: str
    password: SecretStr

user = User(username="john_doe", password="supersecret")
print(user)
# Output: User username='john_doe' password=SecretStr('********')

# Access the raw secret value when needed
print(user.password.get_secret_value())
```

You can safely store secrets in environment variables and load them with `SecretStr`:
```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import SecretStr

class SecureSettings(BaseSettings):
    api_key: SecretStr
    database_password: SecretStr
    mongo_uri: str = "mongodb://localhost:27017"

    model_config = SettingsConfigDict(env_file=".env", env_prefix="APP_")

settings = SecureSettings()
print(settings.api_key)  # Output: SecretStr('********')
```

## MongoDB example

Here's a simple example of using Pydantic v2 models with MongoDB:
```python
from typing import Annotated
from bson import ObjectId
from datetime import datetime
from pydantic import BaseModel, Field, EmailStr, AfterValidator

# Validator for ObjectId
def validate_object_id(value: str | ObjectId) -> ObjectId:
    if not ObjectId.is_valid(value):
        raise ValueError("Invalid ObjectId")
    return ObjectId(value)

# Annotated alias for validated ObjectId
PyObjectId = Annotated[ObjectId, AfterValidator(validate_object_id)]

# MongoDB document model
class UserDocument(BaseModel):
    id: PyObjectId = Field(default_factory=ObjectId, alias="_id")
    name: Annotated[str, Field(min_length=1, max_length=50)]
    email: EmailStr
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True  # Allow using "id" as input even though it's "_id" in Mongo
        arbitrary_types_allowed = True  # Allow ObjectId type, since it is not a built-in Pydantic type


user = UserDocument(name="Alice", email="alice@example.com")
print(user.id)  # <ObjectId> like 68b2625b99495155b9498fe7
print(user.created_at)  # UTC timestamp like 2025-08-30 02:30:51.347367

# This ensures "_id" key is present (MongoDB-friendly)
print(user.model_dump(by_alias=True))
# Output:
# {
#     "_id": ObjectId("..."),
#     "name": "Alice",
#     "email": "alice@example.com",
#     "created_at": datetime(...)
# }
```

You can load a document like
```python
from bson import ObjectId

mongo_data = {
    "_id": ObjectId(),
    "name": "Bob",
    "email": "bob@example.com",
    "created_at": datetime.utcnow()
}

user = UserDocument(**mongo_data)
print(user.name)         # Bob
print(user.id)           # Valid ObjectId
```
