from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    ForeignKey,
    DateTime,
)

from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from database import Base


# ============================================================
# USER
# ============================================================

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String, nullable=False)

    email = Column(
        String,
        unique=True,
        index=True,
        nullable=False
    )

    password_hash = Column(
        String,
        nullable=False
    )

    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc)
    )

    cards = relationship(
        "Card",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    transactions = relationship(
        "Transaction",
        back_populates="user",
        cascade="all, delete-orphan"
    )


# ============================================================
# CARD
# ============================================================

class Card(Base):
    __tablename__ = "cards"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    bank_name = Column(
        String,
        default="HDFC Bank"
    )

    last4 = Column(
        String,
        default="4821"
    )

    credit_limit = Column(
        Float,
        default=150000
    )

    outstanding = Column(
        Float,
        default=0
    )

    credit_score = Column(
        Integer,
        default=750
    )

    bill_due_date = Column(
        Integer,
        nullable=True
    )

    user = relationship(
        "User",
        back_populates="cards"
    )


# ============================================================
# TRANSACTION
# ============================================================

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    merchant = Column(
        String,
        nullable=False
    )

    amount = Column(
        Float,
        nullable=False
    )

    category = Column(
        String,
        default="other"
    )

    reward_coins = Column(
        Integer,
        default=0
    )

    date = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc)
    )

    user = relationship(
        "User",
        back_populates="transactions"
    )