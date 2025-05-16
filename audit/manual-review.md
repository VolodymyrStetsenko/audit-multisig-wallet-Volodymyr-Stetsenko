# 🔍 Manual Code Review — MultiSig Smart Contract

**Author**: Volodymyr Stetsenko  
**Date**: May 2025  
**Target Contract**: `src/MultiSigWallet.sol`  
**Lines of Code**: 123 (excluding comments)  
**Solidity Version**: `^0.8.4`

---

## 📦 1. Contract Overview

The `MultiSig` contract implements a multi-signature wallet, allowing a predefined set of owners to collectively approve and execute transactions. It supports:

- Native ETH transfers via `.call`
- ERC20 token transfers through ABI-encoded `transfer()` calls
- Signature threshold enforcement
- Basic access control and execution logic

The architecture is concise and avoids external dependencies (like OpenZeppelin), but some **security concerns** and **best practice deviations** are present.

---

## 🧱 2. Core Components

| Component          | Description |
|-------------------|-------------|
| `owners[]`        | Array of wallet signers |
| `required`        | Number of confirmations required to execute |
| `Transaction`     | Struct representing a transaction |
| `confirmTransaction()` | Called by owners to approve a transaction |
| `executeTransaction()` | Internal function that performs the call |
| `confirmations`   | Mapping of confirmed transactions per address |
| `executeERC20Transfer()` | External method to transfer ERC20 tokens |

---

## ⚠️ 3. Key Observations

| 🔍 Finding | Category | Status |
|-----------|----------|--------|
| Lacks `nonReentrant` modifier | Reentrancy Risk | ⚠️ Medium |
| No `onlyOwner` modifier, `isOwner()` used manually | Access Control | ✅ Acceptable |
| `addTransaction()` is `internal` | Design | ✅ OK |
| `executeTransaction()` is `internal` | Access Control | ✅ OK |
| No revocation method (`revokeConfirmation`) | UX / Security | ⚠️ Missing |
| No limit on transaction size or gas | DoS Vector | ⚠️ Consider |
| No maximum number of owners enforced | Governance | ❗ High-risk in production |
| No event emitted on ERC20 success/failure | Observability | ⚠️ Missing |

---

## 🚨 4. Initial Risk Areas

| Area | Description | Recommendation |
|------|-------------|----------------|
| **Reentrancy** | `executeTransaction()` performs low-level `.call` | Consider wrapping with `nonReentrant` |
| **Missing revokeConfirmation** | Owners cannot cancel their vote | Add `revokeConfirmation()` to remove confirmation |
| **No rate limit or anti-spam** | Owner can spam transactions | Consider limiting pending transactions |
| **No fallback logic** | No protection from accidental ETH loss | Add `fallback()` for better observability |

---

## 🧭 5. Next Steps

- ✅ Deep dive into each function (`constructor`, `confirmTransaction`, etc.)
- ✅ Slither static analysis results
- ⏳ Forge-based test cases
- ⏳ PDF Report (final stage)


---



## 🔍 6. Function Review: constructor(address[] memory _owners, uint256 _required)

### ✅ Summary

The constructor correctly validates the minimal conditions for owner and threshold setup.

However, it does **not prevent duplicate addresses**, or zero-address owners. This can lead to:
- Centralized control (if one address repeated multiple times)
- Silent failures or unexpected behavior due to `address(0)`


---


### ⚠️ Issues & Recommendations

| ID | Severity | Issue |
|----|----------|-------|
| C-01 | 🔴 High | Duplicate owner addresses are allowed |
| C-02 | 🟠 Medium | Zero-address (`address(0)`) owners are allowed |
| C-03 | 🟡 Low | No cap on number of owners (gas issues with thousands of owners) |


---


### ✅ Suggested Fix (example):

```solidity
for (uint i = 0; i < _owners.length; i++) {
    address owner = _owners[i];
    require(owner != address(0), "Invalid owner: zero address");

    for (uint j = 0; j < i; j++) {
        require(_owners[j] != owner, "Duplicate owner");
    }
}


---


🔍 Function Review: confirmTransaction(uint256 transactionId)
✅ Summary
The function handles confirmation of transactions by wallet owners and attempts automatic execution once the threshold is met.

It performs the following:

Verifies ownership of the caller

Ensures no double-confirming

Updates the confirmation mapping

Triggers execution if the transaction reaches quorum

⚠️ Issues & Recommendations
ID	Severity	Issue	Recommendation
CT-01	🔴 High	Inline call to executeTransaction() can lead to reentrancy if the destination is a malicious contract	Use the [Checks-Effects-Interactions] pattern or move execution to a separate external function
CT-02	🟠 Medium	No gas stipend or fallback logic. If transaction fails, it's not retried or flagged	Track execution result and emit ExecutionFailed event
CT-03	🟡 Low	No option to revoke confirmation (UX/DAO limitation)	Add a revokeConfirmation() function
CT-04	🟡 Low	No logging for failed execution	Emit ExecutionFailed(uint256 txId) on error

🛠️ Suggested Fixes
Separate execution phase to avoid reentrancy:
event ExecutionTriggered(uint256 transactionId);

