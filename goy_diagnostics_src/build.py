#!/usr/bin/env python3
"""Construye GOY_Diagnostics.lua a partir de las secciones s01..s11 y del único
origen del script de servidor (GOY_Diagnostics_Studio_Server.lua), que se
incrusta en la sección 13. Uso: python3 build.py"""
import glob, os
here = os.path.dirname(os.path.abspath(__file__))
parts = sorted(glob.glob(os.path.join(here, "s[0-9][0-9]*.lua")))
studio = open(os.path.join(here, "GOY_Diagnostics_Studio_Server.lua"), encoding="utf-8").read()
level = 0
while ("]" + "=" * level + "]") in studio: level += 1
eq = "=" * max(level, 2)
head = [p for p in parts if os.path.basename(p).startswith("s01")]
body = [p for p in parts if p not in head]
src = "".join(open(p, encoding="utf-8").read() for p in head)
src += ("\n"
        "-- Todo el monitor vive en START(): cambiar de versión (Móvil / PC) lo reinicia limpio.\n"
        "local function START()\n")
src += "".join(open(p, encoding="utf-8").read() for p in body)
src += "\nend\n"
src += ("\n-------------------------------------------------------------------------------\n"
        "-- 13. STUDIO — generado por build.py desde GOY_Diagnostics_Studio_Server.lua (no editar aquí)\n"
        "-------------------------------------------------------------------------------\n"
        f"STUDIO_SCRIPT = [{eq}[\n{studio}]{eq}]\n"
        "START()\n")
open(os.path.join(here, "GOY_Diagnostics.lua"), "w", encoding="utf-8").write(src)
print("GOY_Diagnostics.lua:", src.count("\n"), "líneas,", len(src.encode()), "bytes, secciones:", [os.path.basename(p) for p in parts])
