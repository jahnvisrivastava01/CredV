"""
CredV Backend
FastAPI + SQLite + Multi-User Authentication
"""

import time
from datetime import datetime, timezone

from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from database import engine, Base, get_db
from models import User, Card, Transaction


# ============================================================
# PASSWORD HASHING
# ============================================================

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)


# ============================================================
# CREATE DATABASE TABLES
# ============================================================

Base.metadata.create_all(bind=engine)


# ============================================================
# FASTAPI APP
# ============================================================

app = FastAPI(title="CredV API")


# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# CATEGORIES
# ============================================================

CATEGORIES = [
    "food",
    "shopping",
    "travel",
    "bills",
    "entertainment",
    "other",
]


# ============================================================
# REQUEST MODELS
# ============================================================

class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)
    email: str
    password: str = Field(..., min_length=6)


class LoginRequest(BaseModel):
    email: str
    password: str


# FORGOT PASSWORD REQUEST
class ForgotPasswordRequest(BaseModel):
    email: str
    new_password: str = Field(..., min_length=6)


# UPDATE PROFILE REQUEST
class ProfileUpdateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)
    email: str


class TransactionCreate(BaseModel):
    merchant: str = Field(..., min_length=2)
    amount: float = Field(..., gt=0)
    category: str


class TransactionUpdate(BaseModel):
    merchant: str = Field(..., min_length=2)
    amount: float = Field(..., gt=0)
    category: str


class CardUpdate(BaseModel):
    bankName: str = Field(..., min_length=2)
    last4: str = Field(..., min_length=4, max_length=4)
    creditLimit: float = Field(..., gt=0)
    outstanding: float = Field(..., ge=0)
    creditScore: int = Field(..., ge=300, le=900)


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def card_to_dict(card):
    return {
        "id": card.id,
        "bankName": card.bank_name,
        "last4": card.last4,
        "creditLimit": card.credit_limit,
        "outstanding": card.outstanding,
        "billDueDate": card.bill_due_date,
        "creditScore": card.credit_score,
    }


def transaction_to_dict(transaction):
    return {
        "id": str(transaction.id),
        "merchant": transaction.merchant,
        "amount": transaction.amount,
        "date": transaction.date.isoformat(),
        "category": transaction.category,
        "rewardCoins": transaction.reward_coins,
    }


# ============================================================
# BASIC ROUTES
# ============================================================

@app.get("/")
def root():
    return {
        "message": "CredV API is running",
        "database": "SQLite connected",
        "authentication": "Custom Auth Enabled"
    }


@app.get("/api/health")
def health():
    return {
        "status": "ok",
        "database": "SQLite",
        "time": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================
# AUTH ROUTES
# ============================================================

# ---------------- REGISTER ----------------

@app.post("/api/auth/register")
def register_user(
    user_data: RegisterRequest,
    db: Session = Depends(get_db)
):
    name = user_data.name.strip()
    email = user_data.email.strip().lower()

    # Validate name
    if len(name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Name must contain at least 2 characters"
        )

    # Validate email
    if not email or "@" not in email or "." not in email.split("@")[-1]:
        raise HTTPException(
            status_code=400,
            detail="Please enter a valid email address"
        )

    # Check duplicate email
    existing_user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    # Create user
    new_user = User(
        name=name,
        email=email,
        password_hash=pwd_context.hash(user_data.password)
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Create temporary default card
    # New users will replace this during Card Setup
    default_card = Card(
        user_id=new_user.id,
        bank_name="My Credit Card",
        last4="0000",
        credit_limit=100000,
        outstanding=0,
        credit_score=750,
        bill_due_date=int(time.time()) + 9 * 86400
    )

    db.add(default_card)
    db.commit()

    return {
        "message": "Registration successful",
        "user": {
            "id": new_user.id,
            "name": new_user.name,
            "email": new_user.email,
        }
    }


# ---------------- LOGIN ----------------

@app.post("/api/auth/login")
def login_user(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    email = login_data.email.strip().lower()

    user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    if not pwd_context.verify(
        login_data.password,
        user.password_hash
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    return {
        "message": "Login successful",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
        }
    }


# ---------------- FORGOT PASSWORD ----------------

@app.post("/api/auth/forgot-password")
def forgot_password(
    data: ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    email = data.email.strip().lower()

    user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="No account found with this email"
        )

    if pwd_context.verify(
        data.new_password,
        user.password_hash
    ):
        raise HTTPException(
            status_code=400,
            detail="New password cannot be the same as old password"
        )

    user.password_hash = pwd_context.hash(
        data.new_password
    )

    db.commit()
    db.refresh(user)

    return {
        "message": "Password reset successfully"
    }


# ============================================================
# UPDATE USER PROFILE
# ============================================================

@app.put("/api/user/{user_id}")
def update_user_profile(
    user_id: int,
    data: ProfileUpdateRequest,
    db: Session = Depends(get_db)
):
    # Find user
    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    name = data.name.strip()
    email = data.email.strip().lower()

    # Validate name
    if len(name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Name must contain at least 2 characters"
        )

    # Validate email
    if not email or "@" not in email or "." not in email.split("@")[-1]:
        raise HTTPException(
            status_code=400,
            detail="Please enter a valid email address"
        )

    # Check if ANOTHER user already has this email
    existing_user = (
        db.query(User)
        .filter(
            User.email == email,
            User.id != user_id
        )
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="This email is already registered"
        )

    # Update database
    user.name = name
    user.email = email

    db.commit()
    db.refresh(user)

    return {
        "message": "Profile updated successfully",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
        }
    }


# ============================================================
# GET USER CARD
# ============================================================

@app.get("/api/card/{user_id}")
def get_card(
    user_id: int,
    db: Session = Depends(get_db)
):
    card = (
        db.query(Card)
        .filter(Card.user_id == user_id)
        .first()
    )

    if not card:
        raise HTTPException(
            status_code=404,
            detail="Card not found"
        )

    return card_to_dict(card)


# ============================================================
# UPDATE USER CARD
# ============================================================

@app.put("/api/card/{user_id}")
def update_card(
    user_id: int,
    updated_card: CardUpdate,
    db: Session = Depends(get_db)
):
    card = (
        db.query(Card)
        .filter(Card.user_id == user_id)
        .first()
    )

    if not card:
        raise HTTPException(
            status_code=404,
            detail="Card not found"
        )

    card.bank_name = updated_card.bankName
    card.last4 = updated_card.last4
    card.credit_limit = updated_card.creditLimit
    card.outstanding = updated_card.outstanding
    card.credit_score = updated_card.creditScore

    db.commit()
    db.refresh(card)

    return {
        "message": "Card updated successfully",
        "card": card_to_dict(card),
    }


# ============================================================
# GET USER TRANSACTIONS
# ============================================================

@app.get("/api/transactions/{user_id}")
def get_transactions(
    user_id: int,
    db: Session = Depends(get_db)
):
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == user_id)
        .order_by(Transaction.date.desc())
        .all()
    )

    return [
        transaction_to_dict(transaction)
        for transaction in transactions
    ]


# ============================================================
# ADD TRANSACTION
# ============================================================

@app.post("/api/transactions/{user_id}")
def add_transaction(
    user_id: int,
    transaction: TransactionCreate,
    db: Session = Depends(get_db)
):
    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found"
        )

    category = transaction.category.lower()

    if category not in CATEGORIES:
        category = "other"

    reward_coins = max(
        1,
        int(transaction.amount * 0.05)
    )

    new_transaction = Transaction(
        user_id=user_id,
        merchant=transaction.merchant,
        amount=round(transaction.amount, 2),
        date=datetime.now(timezone.utc),
        category=category,
        reward_coins=reward_coins,
    )

    db.add(new_transaction)

    # Update only this user's card outstanding amount
    card = (
        db.query(Card)
        .filter(Card.user_id == user_id)
        .first()
    )

    if card:
        card.outstanding = round(
            card.outstanding + transaction.amount,
            2
        )

    db.commit()
    db.refresh(new_transaction)

    return {
        "message": "Transaction added successfully",
        "transaction": transaction_to_dict(new_transaction),
    }


# ============================================================
# UPDATE TRANSACTION
# ============================================================

@app.put("/api/transactions/{user_id}/{transaction_id}")
def update_transaction(
    user_id: int,
    transaction_id: int,
    updated_transaction: TransactionUpdate,
    db: Session = Depends(get_db),
):
    transaction = (
        db.query(Transaction)
        .filter(
            Transaction.id == transaction_id,
            Transaction.user_id == user_id
        )
        .first()
    )

    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found"
        )

    category = updated_transaction.category.lower()

    if category not in CATEGORIES:
        category = "other"

    transaction.merchant = updated_transaction.merchant
    transaction.amount = round(
        updated_transaction.amount,
        2
    )
    transaction.category = category

    transaction.reward_coins = max(
        1,
        int(updated_transaction.amount * 0.05)
    )

    db.commit()
    db.refresh(transaction)

    return {
        "message": "Transaction updated successfully",
        "transaction": transaction_to_dict(transaction),
    }


# ============================================================
# DELETE TRANSACTION
# ============================================================

@app.delete("/api/transactions/{user_id}/{transaction_id}")
def delete_transaction(
    user_id: int,
    transaction_id: int,
    db: Session = Depends(get_db),
):
    transaction = (
        db.query(Transaction)
        .filter(
            Transaction.id == transaction_id,
            Transaction.user_id == user_id
        )
        .first()
    )

    if not transaction:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found"
        )

    db.delete(transaction)
    db.commit()

    return {
        "message": "Transaction deleted successfully"
    }


# ============================================================
# USER REWARDS
# ============================================================

@app.get("/api/rewards/{user_id}")
def get_rewards(
    user_id: int,
    db: Session = Depends(get_db)
):
    transactions = (
        db.query(Transaction)
        .filter(Transaction.user_id == user_id)
        .all()
    )

    total_coins = sum(
        transaction.reward_coins
        for transaction in transactions
    )

    return {
        "totalCoins": total_coins,
        "transactions": [
            transaction_to_dict(transaction)
            for transaction in transactions
        ],
    }