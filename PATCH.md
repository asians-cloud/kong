#PATCH 3.4.2

git diff -r 3.4.2..asians-3.4.2 > ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.4.2.patch

git apply -v ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.4.2.patch --reject -v 

When upgrading a big version, rej may happend. find all rej file and then merge it manually.
