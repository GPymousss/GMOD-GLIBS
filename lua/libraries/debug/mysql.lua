concommand.Add("gtest_mysql", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsSuperAdmin() then return end

	local step = tonumber(args[1]) or 1

	if step == 1 then
		print("=== ÉTAPE 1: Test d'ajout de connexion ===")
		gMySQLAddConnection("test_connection", {
			host = "",
			username = "",
			password = "",
			database = "",
			port = 3306
		}, function(result, error)
			if result then
				print("✅ Connexion 'test_connection' ajoutée avec succès!")
			else
				print("❌ Erreur ajout connexion:", error)
			end
		end)

	elseif step == 2 then
		print("=== ÉTAPE 2: Test de connexion MySQL ===")
		gMySQLConnect("test_connection", function(result, error)
			if result then
				print("✅ Connexion MySQL établie avec succès!")
			else
				print("❌ Erreur connexion MySQL:", error)
			end
		end)

	elseif step == 3 then
		print("=== ÉTAPE 3: Test de création de table ===")
		gMySQLCreateTable("test_connection", "test_users", {
			id = "INT PRIMARY KEY AUTO_INCREMENT",
			name = "VARCHAR(255) NOT NULL",
			age = "INT",
			email = "VARCHAR(255)"
		}, function(result, error)
			if result then
				print("✅ Table 'test_users' créée avec succès!")
			else
				print("❌ Erreur création table:", error)
			end
		end)

	elseif step == 4 then
		print("=== ÉTAPE 4: Test d'insertion de données ===")
		gMySQLInsert("test_connection", "test_users", {
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

	elseif step == 5 then
		print("=== ÉTAPE 5: Test de sélection de données ===")
		gMySQLSelect("test_connection", "test_users", nil, nil, function(result, error)
			if result then
				print("✅ Données récupérées:", #result, "lignes")
				for i, row in ipairs(result) do
					print("  - ID:", row.id, "Name:", row.name, "Age:", row.age, "Email:", row.email)
				end
			else
				print("❌ Erreur sélection:", error)
			end
		end)

	elseif step == 6 then
		print("=== ÉTAPE 6: Test de sélection avec conditions ===")
		gMySQLSelect("test_connection", "test_users", {"name", "age"}, {age = 25}, function(result, error)
			if result then
				print("✅ Utilisateurs de 25 ans trouvés:", #result, "lignes")
				for i, row in ipairs(result) do
					print("  - Name:", row.name, "Age:", row.age)
				end
			else
				print("❌ Erreur sélection conditionnelle:", error)
			end
		end)

	elseif step == 7 then
		print("=== ÉTAPE 7: Test de mise à jour ===")
		gMySQLUpdate("test_connection", "test_users", {
			age = 26,
			email = "john.doe@newmail.com"
		}, {name = "John Doe"}, function(result, error)
			if result then
				print("✅ Utilisateur mis à jour avec succès!")
			else
				print("❌ Erreur mise à jour:", error)
			end
		end)

	elseif step == 8 then
		print("=== ÉTAPE 8: Test de suppression ===")
		gMySQLDelete("test_connection", "test_users", {age = 26}, function(result, error)
			if result then
				print("✅ Utilisateurs supprimés avec succès!")
			else
				print("❌ Erreur suppression:", error)
			end
		end)

	elseif step == 9 then
		print("=== ÉTAPE 9: Test de validation des erreurs ===")
		gMySQLInsert("test_connection", "test_users", {
			["SELECT"] = "test",
			invalid_data = {}
		}, function(result, error)
			if not result then
				print("✅ Erreur correctement détectée:", error)
			else
				print("❌ L'erreur n'a pas été détectée!")
			end
		end)

	elseif step == 10 then
		print("=== ÉTAPE 10: Test des fonctions utilitaires ===")
		gMySQLListTables("test_connection", function(tables, error)
			if tables then
				print("✅ Tables MySQL:")
				for i, table in ipairs(tables) do
					print("  -", table)
				end
			else
				print("❌ Erreur liste tables:", error)
			end
		end)

		timer.Simple(1, function()
			gMySQLTableInfo("test_connection", "test_users", function(info, error)
				if info then
					print("✅ Informations sur la table test_users:")
					print("  Colonnes:", info.columns and #info.columns or 0)
					print("  Index:", info.indexes and #info.indexes or 0)
				else
					print("❌ Erreur info table:", error)
				end
			end)
		end)

	elseif step == 11 then
		print("=== ÉTAPE 11: Test complet (insertion multiple) ===")
		local users = {
			{name = "Alice", age = 30, email = "alice@test.com"},
			{name = "Bob", age = 35, email = "bob@test.com"},
			{name = "Charlie", age = 28, email = "charlie@test.com"}
		}

		for i, user in ipairs(users) do
			timer.Simple(i * 0.1, function()
				gMySQLInsert("test_connection", "test_users", user, function(result, error)
					if result then
						print("✅ Utilisateur", user.name, "inséré")
					else
						print("❌ Erreur pour", user.name, ":", error)
					end
				end)
			end)
		end

	elseif step == 12 then
		print("=== ÉTAPE 12: Test de connexion inexistante ===")
		gMySQLSelect("connexion_inexistante", "test_users", nil, nil, function(result, error)
			if not result then
				print("✅ Erreur de connexion détectée:", error)
			else
				print("❌ L'erreur de connexion n'a pas été détectée!")
			end
		end)

	elseif step == 13 then
		print("=== ÉTAPE 13: Nettoyage - Suppression table et connexion ===")
		gMySQLConnect("test_connection", function(connected, err)
			if connected then
				local db = GPYMOUSSS.MySQL.connections["test_connection"].db
				local query = db:query("DROP TABLE IF EXISTS test_users")

				query.onSuccess = function()
					print("✅ Table de test supprimée!")

					gMySQLDisconnect("test_connection", function()
						gMySQLRemoveConnection("test_connection", function(result, error)
							if result then
								print("✅ Connexion supprimée!")
							else
								print("❌ Erreur suppression connexion:", error)
							end
						end)
					end)
				end

				query.onError = function(_, error)
					print("❌ Erreur suppression table:", error)
				end

				query:start()
			else
				print("❌ Impossible de se connecter pour nettoyer")
			end
		end)

	else
		print("=== Tests MySQL disponibles ===")
		print("Usage: gtest_mysql <étape>")
		print("1 - Ajout de connexion")
		print("2 - Connexion MySQL")
		print("3 - Création de table")
		print("4 - Insertion de données")
		print("5 - Sélection de toutes les données")
		print("6 - Sélection avec conditions")
		print("7 - Mise à jour")
		print("8 - Suppression")
		print("9 - Test de validation des erreurs")
		print("10 - Fonctions utilitaires")
		print("11 - Test complet (insertion multiple)")
		print("12 - Test de connexion inexistante")
		print("13 - Nettoyage (suppression table + connexion)")
		print("\nExemple: gtest_mysql 1")
		print("\nATTENTION: Configurez d'abord votre serveur MySQL !")
	end
end)