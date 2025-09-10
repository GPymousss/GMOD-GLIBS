concommand.Add("gtest_sqlite", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end

	local step = tonumber(args[1]) or 1

	if step == 1 then
		print("=== ÉTAPE 1: Test de création de table ===")
		gSQLiteCreateTable("test_users", {
			id = "INTEGER PRIMARY KEY AUTOINCREMENT",
			name = "TEXT NOT NULL",
			age = "INTEGER",
			email = "TEXT"
		}, function(result, error)
			if result then
				print("✅ Table 'test_users' créée avec succès!")
			else
				print("❌ Erreur création table:", error)
			end
		end)

	elseif step == 2 then
		print("=== ÉTAPE 2: Test d'insertion de données ===")
		gSQLiteInsert("test_users", {
			name = "John Doe",
			age = 25,
			email = "john@example.com"
		}, function(result, error)
			if result then
				print("✅ Utilisateur inséré avec succès!")
			else
				print("❌ Erreur insertion:", error)
			end
		end)

	elseif step == 3 then
		print("=== ÉTAPE 3: Test de sélection de données ===")
		gSQLiteSelect("test_users", nil, nil, function(result, error)
			if result then
				print("✅ Données récupérées:", #result, "lignes")
				for i, row in ipairs(result) do
					print("  - ID:", row.id, "Name:", row.name, "Age:", row.age, "Email:", row.email)
				end
			else
				print("❌ Erreur sélection:", error)
			end
		end)

	elseif step == 4 then
		print("=== ÉTAPE 4: Test de sélection avec conditions ===")
		gSQLiteSelect("test_users", {"name", "age"}, {age = 25}, function(result, error)
			if result then
				print("✅ Utilisateurs de 25 ans trouvés:", #result, "lignes")
				for i, row in ipairs(result) do
					print("  - Name:", row.name, "Age:", row.age)
				end
			else
				print("❌ Erreur sélection conditionnelle:", error)
			end
		end)

	elseif step == 5 then
		print("=== ÉTAPE 5: Test de mise à jour ===")
		gSQLiteUpdate("test_users", {
			age = 26,
			email = "john.doe@newmail.com"
		}, {name = "John Doe"}, function(result, error)
			if result then
				print("✅ Utilisateur mis à jour avec succès!")
			else
				print("❌ Erreur mise à jour:", error)
			end
		end)

	elseif step == 6 then
		print("=== ÉTAPE 6: Test de suppression ===")
		gSQLiteDelete("test_users", {age = 26}, function(result, error)
			if result then
				print("✅ Utilisateurs supprimés avec succès!")
			else
				print("❌ Erreur suppression:", error)
			end
		end)

	elseif step == 7 then
		print("=== ÉTAPE 7: Test de validation des erreurs ===")
		gSQLiteInsert("test_users", {
			["SELECT"] = "test",
			invalid_data = {}
		}, function(result, error)
			if not result then
				print("✅ Erreur correctement détectée:", error)
			else
				print("❌ L'erreur n'a pas été détectée!")
			end
		end)

	elseif step == 8 then
		print("=== ÉTAPE 8: Test des fonctions utilitaires ===")
		print("Tables SQLite:")
		local tables = gSQLiteListTables()
		for i, table in ipairs(tables) do
			print("  -", table)
		end

		print("\nInformations sur la table test_users:")
		local info = gSQLiteTableInfo("test_users")
		if info then
			print("  Colonnes:", info.columns and #info.columns or 0)
			print("  Index:", info.indexes and #info.indexes or 0)
		end

	elseif step == 9 then
		print("=== ÉTAPE 9: Test complet (insertion multiple) ===")
		local users = {
			{name = "Alice", age = 30, email = "alice@test.com"},
			{name = "Bob", age = 35, email = "bob@test.com"},
			{name = "Charlie", age = 28, email = "charlie@test.com"}
		}

		for i, user in ipairs(users) do
			gSQLiteInsert("test_users", user, function(result, error)
				if result then
					print("✅ Utilisateur", user.name, "inséré")
				else
					print("❌ Erreur pour", user.name, ":", error)
				end
			end)
		end

	elseif step == 10 then
		print("=== ÉTAPE 10: Nettoyage - Suppression de la table de test ===")
		local result = sql.Query("DROP TABLE IF EXISTS test_users")
		if result ~= false then
			print("✅ Table de test supprimée!")
		else
			print("❌ Erreur suppression table:", sql.LastError())
		end

	else
		print("=== Tests SQLite disponibles ===")
		print("Usage: gtest_sqlite <étape>")
		print("1 - Création de table")
		print("2 - Insertion de données")
		print("3 - Sélection de toutes les données")
		print("4 - Sélection avec conditions")
		print("5 - Mise à jour")
		print("6 - Suppression")
		print("7 - Test de validation des erreurs")
		print("8 - Fonctions utilitaires")
		print("9 - Test complet (insertion multiple)")
		print("10 - Nettoyage (suppression table)")
		print("\nExemple: gtest_sqlite 1")
	end
end)