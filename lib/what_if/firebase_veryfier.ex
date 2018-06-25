defmodule WhatIf.FirebaseVeryfier do

  # returns {true, user_id} or false
  def verify_jwt(token) do
    kid = get_kid(token)
    firebase_keys = get_public_keys()
    case Map.get(firebase_keys, kid) do
      jwk = %JOSE.JWK{} ->
        verified = JOSE.JWT.verify_strict(jwk, ["RS256"], token)
        case verified do
          {true, fields, _} ->
            {true, fields.fields["user_id"]}
          _ ->
            false
        end
      _ ->
        false
    end
  end

  defp get_kid(token) do
    try do
      token
      |> JOSE.JWS.peek_protected()
      |> JOSE.decode()
      |> Map.get("kid")
    catch
      e, f ->
        nil
    end
  end

  defp get_public_keys() do
    {:ok, {{_, 200, _}, _, body}} = :httpc.request(:get, {'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com', []}, [autoredirect: true], [])
    JOSE.JWK.from_firebase(IO.iodata_to_binary(body))
  end


end
