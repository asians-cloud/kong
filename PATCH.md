#PATCH 3.4.2

git diff -r 3.4.2..asians-3.4.2 > ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.4.2.patch

git format-patch 3.4.2..asians-3.4.2 --stdout > ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.4.2.patch
