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
src = "".join(open(p, encoding="utf-8").read() for p in parts)
src += ("\n-------------------------------------------------------------------------------\n"
        "-- 13. STUDIO — generado por build.py desde GOY_Diagnostics_Studio_Server.lua (no editar aquí)\n"
        "-------------------------------------------------------------------------------\n"
        f"STUDIO_SCRIPT = [{eq}[\n{studio}]{eq}]\n")
open(os.path.join(here, "GOY_Diagnostics.lua"), "w", encoding="utf-8").write(src)
print("GOY_Diagnostics.lua:", src.count("\n"), "líneas,", len(src.encode()), "bytes, secciones:", [os.path.basename(p) for p in parts])
