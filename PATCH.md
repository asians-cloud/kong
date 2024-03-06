#PATCH 3.4.2

git diff -r 3.4.2..asians-3.4.2 > ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.4.2.patch

git format-patch 3.4.2..asians-3.4.2 --stdout > ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.4.2.patch



git checkout release/3.6.1
git branch asians-3.6.1
git checkout asians-3.6.1
patch -p1 <  ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.4.2.patch
#Then check all merge files, manually merge rej files if it has.
git add .
git commit -am "merged asians"
git push asians asians-3.6.1

git diff -r release/3.6.1..asians-3.6.1 > ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.6.1.patch



