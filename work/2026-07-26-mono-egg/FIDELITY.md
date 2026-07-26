# The mono egg — fidelity ledger

**The bar (Kody, 2026-07-26):** a factory device, **no internet**, a local model
that has never heard of RAPP. Hatch one cartridge and RAPP exists, works, and
can be understood. Loop until an adversarial review agrees that is true.

Artifact: `kody-w/rapp-batcave` → `cubbies/kody-w/eggs/rapp-mono.egg`
(6,423,236 bytes, sha `73253ec5291fd26c`). Builder: `tools/monoegg.py`.

## Proven (exercised, not asserted)

| claim | evidence |
|---|---|
| hatches into a clean dir | 44 files + registry, `monoegg hatch` |
| installs with the network forbidden | `pip --no-index --find-links ../wheels` → 16 packages |
| the brainstem boots | health 200, 25 routes, 222 KB UI at `/` |
| kernel is byte-identical to source | `cmp` clean against `RAPP/rapp_brainstem/brainstem.py` |
| an agent installs offline from the bundle | `AccountIntelligenceAgent` copied in → 4 live, 0 quarantined, 0 auto-install |
| survives the batcave round trip | fresh clone → sha matches sidecar → 11/11 verify checks |

## Not yet true — the loop's worklist

1. **No model.** The egg carries no local model and cannot. The factory test
   supplies one; until then "a naive model can operate it" is **untested**, and
   it is the single biggest unproven claim.
2. **`mind/` is thinner than Article LVII.2 requires.** It has topology and
   divergence; it does **not** have the interface index (every `__manifest__`
   across the estate), which LVII.2 lists as priority 2.
3. **Ecosystem repos absent.** rapp-holo (the interaction standard), rapp-train
   (the release vehicle), the installer, and the tower's own tools are not in
   the cartridge. A rebuild gets the kernel but not the railroad.
4. **No self-test inside the egg.** A factory device cannot currently prove its
   own cartridge is good without this repo's tooling. `seed/selftest.sh` should
   hatch-boot-probe and print a verdict.
5. **Twin chat untested.** The cartridge is meant to hatch "as a local twin";
   the twinchat path has not been exercised against a hatched instance.
6. **Registry agents unvalidated.** 242 bundled; only one was proven to load.
   An unknown number may fail to import, or trigger the pip oracle.

## Rule for this loop

Every iteration must **prove** a line moved from the second table to the first,
with a command and its output. A claim without an exercised artifact does not
count as progress.
