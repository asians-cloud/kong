#PATCH 3.5.0

git diff -r 3.5.0..asians-3.5.0 > ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.5.0.patch

git apply -v ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.5.0.patch --reject -v 

When upgrading a big version, rej may happend. find all rej file and then merge it manually.
