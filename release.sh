#!/bin/bash

CURRENT_VERSION=$(cat common/banner.go | grep Version | cut -d '"' -f 2)
TO_UPDATE=(
  common/banner.go
)

read -p "[?] Did you remember to update CHANGELOG.md? "
read -p "[?] Did you remember to update README.md with new features/changes? "

echo -n "[*] Current version is $CURRENT_VERSION. Enter new version: "
read NEW_VERSION
echo "[*] Pushing and tagging version $NEW_VERSION in 5 seconds..."
sleep 5

for file in "${TO_UPDATE[@]}"; do
  echo "[*] Patching $file ..."
  sed -i "s/$CURRENT_VERSION/$NEW_VERSION/g" $file
  git add $file
done

git add CHANGELOG.md
git commit -m "Releasing v$NEW_VERSION"
git push

git tag -a v$NEW_VERSION -m "Release v$NEW_VERSION"
git push origin v$NEW_VERSION

echo
echo "[*] All done, v$NEW_VERSION released."
