# Белый курсор в Waydroid / White cursor in Waydroid

![до / после — before / after](preview.png)

[Русский](#русский) · [English](#english)

---

## Русский

Белый курсор мыши внутри Waydroid. Тема курсоров KDE/GNOME на это не влияет:
в Waydroid курсор рисует сам Android.

Проверено: Waydroid 1.6.3, LineageOS 20 (Android 13) x86_64 GAPPS, KDE Plasma 6.8 (Wayland),
CachyOS. Подходит и для образов с libhoudini/libndk — их файлы не затрагиваются.

### Быстро

```bash
git clone https://github.com/pioner14/waydroid-white-cursor
cd waydroid-white-cursor
sudo bash install.sh          # встроить белый курсор (копия образа сохраняется)
sudo bash install_guard.sh    # необязательно: вернуть курсор, если образ обновят
```

Откат: `sudo bash install.sh remove`.

### Как это устроено

**1. Откуда берётся курсор.** Когда к Android подключена мышь, системный сервис ввода
(`InputManager` → `PointerController`) рисует указатель отдельным слоем-«спрайтом».
Картинка — ресурс `@drawable/pointer_arrow` из `/system/framework/framework-res.apk`
(Android 13: `pointer_arrow_icon.xml` ссылается на PNG `pointer_arrow` в папках
mdpi/hdpi/xhdpi/xxhdpi). Композитор Waydroid (`hwcomposer.waydroid.so`) берёт этот слой
и отдаёт его хосту через `wl_pointer.set_cursor` (или подповерхностью, если
`persist.waydroid.cursor_on_subsurface=true`). Поэтому хост показывает ровно ту стрелку,
которую нарисовал Android, — чёрную.

**2. Как заменить картинку, не трогая framework-res.apk.** В Android есть механизм
RRO (Runtime Resource Overlay): маленький APK без кода, который подменяет ресурсы
другого пакета по имени. Наш оверлей нацелен на пакет `android` и содержит только
`drawable/pointer_arrow` и `drawable/pointer_arrow_large` (см. `AndroidManifest.xml`, `res/`).

**3. Белая стрелка.** Исходные PNG взяты из framework-res.apk. У непрозрачных пикселей
(альфа ≥ 200) яркость инвертирована: чёрная заливка стала белой, белая обводка — тёмной.
Полупрозрачная тень оставлена как есть, иначе вокруг стрелки появляется светлое «сияние».

**4. Подпись.** Ресурсы framework в основном не объявлены как overlayable, поэтому Android
разрешает их менять только оверлеям, подписанным тем же ключом, что и framework, или
встроенным в системный раздел. Образы Waydroid (LineageOS, `test-keys`) подписаны открытым
тестовым ключом AOSP (`build/target/product/security/platform`, SHA-1 сертификата
`27:19:6E:38:...:3D:FA`). Им подписан и наш APK. `build.sh` скачивает ключ с
android.googlesource.com — он публичный, в репозитории его нет.

**5. Почему оверлей встроен в образ, а не установлен как приложение.** Первая попытка была
обычной: `pm install` + `cmd overlay enable`. Оверлей включался, `system_server` его
подгружал, но курсор оставался чёрным: `PointerController` загружает картинку при старте,
раньше, чем менеджер оверлеев применяет оверлеи из `/data`. Перечитать курсоры на лету
можно сменой плотности экрана (`wm density`), но это перезапускает окна приложений —
игра при этом зависла. Статический оверлей (`android:isStatic="true"`) из
`/system/product/overlay` подключается к ресурсам framework с самого начала загрузки,
поэтому курсор белый сразу.

**6. Встраивание.** `install.sh` останавливает Waydroid, делает копию `system.img`
(на btrfs — reflink, без лишнего места), монтирует образ на запись (`mount -o loop,rw`)
и кладёт `WhiteCursor.apk` в `/system/product/overlay/WhiteCursor/`. Места в образе
хватает (ext4, около 1,8 ГБ свободно).

**7. Чтобы не пропало.** Изменение хранится в `system.img` и переживает перезагрузки.
Потерять его можно только при замене образа (`waydroid upgrade`, переустановка).
`install_guard.sh` добавляет к `waydroid-container.service` `ExecStartPre=-…/ensure_white_cursor.sh`:
перед каждым стартом скрипт через `debugfs` проверяет, есть ли файл в образе,
и при необходимости кладёт его обратно. Минус перед командой — ошибка проверки
не мешает Waydroid стартовать.

### Если курсор вообще пропал

Отдельная проблема: с `persist.waydroid.cursor_on_subsurface=true` и KWin 6.8.2
(драйвер NVIDIA) курсор над окном Waydroid не виден. Вернуть по умолчанию:

```bash
sudo waydroid shell -- setprop persist.waydroid.cursor_on_subsurface false
waydroid session stop   # и запустить заново
```

### Файлы

| Файл | Что это |
|---|---|
| `AndroidManifest.xml` | манифест статического оверлея на пакет `android` |
| `res/drawable-*/pointer_arrow*.png` | белые стрелки |
| `prebuilt/WhiteCursor.apk` | готовый оверлей |
| `build.sh` | сборка из `res/` (Android SDK build-tools) |
| `install.sh` | встроить в `system.img` / `remove` — откатить |
| `install_guard.sh`, `ensure_white_cursor.sh` | проверка при старте Waydroid |

---

## English

A white mouse cursor inside Waydroid. Your KDE/GNOME cursor theme does not affect it:
inside Waydroid the cursor is drawn by Android itself.

Tested: Waydroid 1.6.3, LineageOS 20 (Android 13) x86_64 GAPPS, KDE Plasma 6.8 (Wayland),
CachyOS. Works with libhoudini/libndk images — their files are not touched.

### Quick start

```bash
git clone https://github.com/pioner14/waydroid-white-cursor
cd waydroid-white-cursor
sudo bash install.sh          # bake the white cursor in (a backup image is kept)
sudo bash install_guard.sh    # optional: restore it if the image gets replaced
```

Revert: `sudo bash install.sh remove`.

### How it works

**1. Where the cursor comes from.** With a mouse attached, Android's input service
(`InputManager` → `PointerController`) draws the pointer as a sprite layer. The bitmap is
`@drawable/pointer_arrow` from `/system/framework/framework-res.apk`. Waydroid's
`hwcomposer.waydroid.so` takes that layer and hands it to the host via
`wl_pointer.set_cursor` (or a subsurface when `persist.waydroid.cursor_on_subsurface=true`).
So the host shows exactly Android's arrow — a black one.

**2. Replacing the bitmap without touching framework-res.apk.** Android's RRO
(Runtime Resource Overlay) is a code-less APK that replaces another package's resources
by name. This overlay targets `android` and contains only `drawable/pointer_arrow`
and `drawable/pointer_arrow_large`.

**3. The white arrow.** The original PNGs from framework-res.apk with the luminance of
opaque pixels (alpha ≥ 200) inverted: black fill → white, white outline → dark.
The translucent drop shadow is kept, otherwise the arrow gets a light halo.

**4. Signing.** Most framework resources are not declared overlayable, so Android only lets
overlays signed with the framework key, or preinstalled in a system partition, change them.
Waydroid images (LineageOS, `test-keys`) are signed with the public AOSP test platform key;
the APK is signed with it too. `build.sh` downloads the key from android.googlesource.com;
it is public and not stored here.

**5. Why it is baked into the image instead of installed as an app.** A regular overlay
(`pm install` + `cmd overlay enable`) got enabled and loaded by `system_server`, but the
cursor stayed black: `PointerController` loads the bitmap at boot, before overlays from
`/data` are applied. Reloading on the fly via `wm density` restarts app windows and hung
the game. A static overlay (`android:isStatic="true"`) in `/system/product/overlay` is part
of the framework resources from early boot, so the cursor is white right away.

**6. Baking in.** `install.sh` stops Waydroid, backs up `system.img` (reflink on btrfs),
loop-mounts it read-write and puts `WhiteCursor.apk` into
`/system/product/overlay/WhiteCursor/`.

**7. Keeping it.** The change lives in `system.img` and survives reboots. It is lost only
when the image is replaced (`waydroid upgrade`, reinstall). `install_guard.sh` adds
`ExecStartPre=-…/ensure_white_cursor.sh` to `waydroid-container.service`: before every start
it checks the image with `debugfs` and re-adds the overlay if missing. The leading `-`
means a failed check never blocks Waydroid from starting.

### Cursor disappeared entirely

A separate issue: with `persist.waydroid.cursor_on_subsurface=true` and KWin 6.8.2
(NVIDIA driver) the cursor is invisible over the Waydroid window. Reset to default:

```bash
sudo waydroid shell -- setprop persist.waydroid.cursor_on_subsurface false
waydroid session stop   # then start again
```

## License

Apache License 2.0 — see [LICENSE](LICENSE). The arrow images are derived from the
Android Open Source Project (`frameworks/base`, Apache 2.0).
