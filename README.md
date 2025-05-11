# 🔐 Multi-Signature Wallet Audit — Volodymyr Stetsenko

> 🛡️ **Full manual security audit of a custom Multi-Signature Wallet smart contract**, written and audited by [Volodymyr Stetsenko](https://github.com/VolodymyrStetsenko) as a public portfolio case.

---

## 📜 Contract Overview

- **Project:** MultiSig Wallet with ERC20 token support  
- **Language:** Solidity `^0.8.4`  
- **Audit Scope:** 1 contract, full codebase review  
- **Audit Type:** Manual logic review + static analysis  
- **Status:** ✅ Initial audit completed  
- **Author:** Volodymyr Stetsenko  
- **Date:** 2025

---

## 🗂 Structure

| Folder      | Description                                   |
|-------------|-----------------------------------------------|
| `contracts/` | Source smart contract code                    |
| `report/`    | Audit report files (.md and PDF)              |
| `assets/`    | Architecture diagrams and visuals (optional) |
| `README.md`  | This file — repository description            |

---

## 📑 Audit Reports

- 📄 [Audit Report (Markdown)](./report/report.md)
- 📄 Audit Report (PDF) – coming soon

---

## 🧠 What Was Audited

- ✅ Core transaction logic
- ✅ Signature confirmation system
- ✅ ERC20 execution via encoded calldata
- ✅ State tracking (executed, confirmations)
- ✅ Access control checks (isOwner)
- ✅ Reentrancy safety via atomic execution
- ✅ Event logging and traceability

---

## ⚠️ Findings Overview

| ID | Title                          | Severity | Status     |
|----|--------------------------------|----------|------------|
| 1  | No protection against replay   | High     | Reported   |
| 2  | Call-based execution risks     | Medium   | Reported   |
| 3  | No expiry for transactions     | Low      | Reported   |
| 4  | Missing safeguards in ERC20    | Medium   | Reported   |

> 📌 Full details in [report/report.md](./report/report.md)

---

## 🎯 Goals of This Audit

- Demonstrate real-world security skills
- Build public portfolio as smart contract auditor
- Establish trust, transparency and professionalism

---

## ✍️ License

MIT — open for learning, research and portfolio presentation.
