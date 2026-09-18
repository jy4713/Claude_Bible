#!/usr/bin/env python3
"""
성경앱 assets 설정 스크립트
data/ 폴더의 DB 파일을 bible_app/assets/ 폴더로 복사합니다.

사용법: python setup_assets.py
"""
import os, shutil, sys

BASE   = os.path.dirname(os.path.abspath(__file__))
DATA   = os.path.join(BASE, 'data')
ASSETS = os.path.join(BASE, 'bible_app', 'assets')

COPY_MAP = {
    # source (relative to DATA)              : dest (relative to ASSETS)
    'bible/개역개정.bdb'      : 'bible/개역개정.bdb',
    'bible/개역한글.bdb'      : 'bible/개역한글.bdb',
    'bible/KJV1769.bdb'      : 'bible/KJV1769.bdb',
    'bible/NIV.bdb'          : 'bible/NIV.bdb',
    'bible/WEB.bdb'          : 'bible/WEB.bdb',
    'bible/NET.bdb'          : 'bible/NET.bdb',
    'bible/킹흠정역.bdb'      : 'bible/킹흠정역.bdb',
    'bible/바른성경.bdb'      : 'bible/바른성경.bdb',
    'bible/새번역.bdb'        : 'bible/새번역.bdb',
    'bible/쉬운성경.bdb'      : 'bible/쉬운성경.bdb',
    'bible/현대인의성경.bdb'   : 'bible/현대인의성경.bdb',
    'bible/현대어성경.bdb'    : 'bible/현대어성경.bdb',
    'commentary/만나주석.cdb' : 'commentary/만나주석.cdb',
    'hymn/새찬송가.hdb'       : 'hymn/새찬송가.hdb',
    'hymn/새찬송가.cmp'       : 'hymn/새찬송가.cmp',
    'dic/HebGrkKo.dct'       : 'dic/HebGrkKo.dct',
    'dic/HebGrkEn.dct'       : 'dic/HebGrkEn.dct',
}

def main():
    total = 0
    for rel_src, rel_dst in COPY_MAP.items():
        src = os.path.join(DATA, rel_src.replace('/', os.sep))
        dst = os.path.join(ASSETS, rel_dst.replace('/', os.sep))
        if not os.path.exists(src):
            print(f'[SKIP] 파일 없음: {rel_src}')
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if os.path.exists(dst):
            print(f'[OK]   이미 존재: {rel_dst}')
            total += 1
            continue
        size = os.path.getsize(src)
        print(f'[COPY] {rel_src}  →  {rel_dst}  ({size/1024/1024:.1f} MB)', end='', flush=True)
        shutil.copy2(src, dst)
        print('  ✓')
        total += 1
    print(f'\n완료: {total}/{len(COPY_MAP)} 파일 준비됨')
    print('\n다음 단계:')
    print('  cd bible_app')
    print('  flutter pub get')
    print('  flutter run                    # 기기/에뮬레이터')
    print('  flutter run -d chrome          # 웹 브라우저')
    print('  flutter build apk --release    # 릴리스 APK')

if __name__ == '__main__':
    main()
