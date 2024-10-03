# Upgrade steps:
git checkout origin 3.8.0
git merge origin 3.4.2 --strategy=ours
git pull asians asians-3.4.2
# Then solve all conflicts and check update.


#PATCH 3.4.2

git diff -U3 3.4.2..asians-3.4.2 -- . ':(exclude)CHANGELOG.md' > ../gaius-pusher/roles/gaius.kong/files/kong/asians-3.4.2.patch

