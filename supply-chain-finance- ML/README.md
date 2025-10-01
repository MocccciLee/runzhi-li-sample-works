# Supply Chain Finance — Machine Learning Project

This folder contains my project on supply chain finance (SCF): scraping, cleaning, visualization, and predictive modeling.

> **Note on language**  
> The notebooks were originally written in China. For sharing, I translated the **markdown cells** into English.  
> **Code comments inside cells may remain in Chinese** to preserve my original thought process.  
> Please treat the notebooks mainly as a reference to the workflow and logic.

---

## 📂 Structure
- `code/` — Jupyter notebooks (01–05).
- `data/`
  - `raw/` — original Excel files.
  - `processed/` — cleaned datasets (e.g., `最终数据_供应链金融成功分析结果.xlsx`).
- `outputs/`
  - `figures/` — final visualization images (file names in English).

---

## 🔁 Reproducibility
This project is **not fully reproducible**:
- The scraping notebook requires a trial account on JianweiData and manual pagination.
- Some intermediate steps involved manual corrections in Excel.
- Paths in notebooks 01–04 are absolute and kept as-is for transparency.

**What can run now**
- In `05_ml-core.ipynb` I switched the data path to a **relative path**.  
  If you open the notebook from `code/`, it will load:
