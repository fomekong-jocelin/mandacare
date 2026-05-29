# Repository Guidelines

## Project Structure & Module Organization

This repository currently stores project documentation and visual assets rather than application source code.

- `expressions_besoins/`: requirements and specification documents, including the MandaCare cahier des charges in `.docx` and `.pdf` formats.
- `logo_fiche_exam/`: generated logo and exam-sheet image assets.
- `mockups/`: generated UI mockup images.
- Root-level `.pdf` files: reference forms, attestations, questionnaires, consultation plates, and census notes.
- `.idea/`: local JetBrains IDE metadata. Avoid editing it unless the change is intentionally project-wide.

Keep new assets in the most specific existing folder. Create a new top-level folder only for a clearly distinct document category.

## Build, Test, and Development Commands

There is no application build system, package manifest, or automated test runner in this checkout.

Useful local inspection commands:

```powershell
Get-ChildItem -Recurse -File
```

Lists all tracked working files for inventory checks.

```powershell
Get-ChildItem -Recurse -File *.pdf,*.docx,*.png
```

Verifies the expected document and image asset types.

Before sharing updated documents, open the changed `.pdf`, `.docx`, or `.png` files locally and confirm that pages, images, and text render correctly.

## Coding Style & Naming Conventions

No source-code style guide applies yet. For repository assets, use descriptive filenames with a consistent subject, date, and version when applicable, for example:

- `Cahier-des-charges-MandaCare-v2.docx`
- `Questionnaire-Fosa-2024-05-18.pdf`
- `Mockup-dashboard-v1.png`

Prefer hyphenated names without accidental typos or duplicate suffixes. Keep original filenames only when they are official source documents.

## Testing Guidelines

Manual review is the current validation process. For document updates, verify spelling, pagination, embedded images, and exported PDF fidelity. For image assets, confirm resolution, cropping, legibility, and that the asset belongs in the selected folder.

If application code is later added, include tests beside the implementation or in a conventional `tests/` directory and document the command here.

## Commit & Pull Request Guidelines

This checkout does not include git history, so no existing commit convention can be inferred. Use concise Conventional Commit-style messages, such as `docs: update MandaCare requirements` or `assets: add exam sheet mockups`.

Pull requests should include a short purpose statement, a list of changed documents or assets, before/after screenshots for visual changes, and links to related requirements or issue references when available.

## Security & Configuration Tips

Review documents for personal, medical, or administrative data before committing or sharing. Do not add credentials, private IDs, or unredacted patient information unless the repository is explicitly authorized for that data.
