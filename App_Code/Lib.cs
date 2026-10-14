using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Text;

public class Lib
{
    public static int SqlCommandTimeoutSeconds()
    {
        string value = ConfigurationManager.AppSettings["SqlCommandTimeoutSeconds"];
        int seconds;
        if (int.TryParse(value, out seconds) && seconds >= 0) return seconds;
        return 0;
    }

    public static SqlCommand SqlCommand()
    {
        SqlCommand cmd = new SqlCommand();
        cmd.CommandTimeout = SqlCommandTimeoutSeconds();
        return cmd;
    }

    public static SqlCommand SqlCommand(string commandText, SqlConnection connection)
    {
        SqlCommand cmd = new SqlCommand(commandText, connection);
        cmd.CommandTimeout = SqlCommandTimeoutSeconds();
        return cmd;
    }

    public static SqlCommand SqlCommand(string commandText, SqlConnection connection, SqlTransaction transaction)
    {
        SqlCommand cmd = new SqlCommand(commandText, connection, transaction);
        cmd.CommandTimeout = SqlCommandTimeoutSeconds();
        return cmd;
    }

    public static SqlDataAdapter SqlDataAdapter(SqlCommand command)
    {
        command.CommandTimeout = SqlCommandTimeoutSeconds();
        return new SqlDataAdapter(command);
    }

    public static SqlDataAdapter SqlDataAdapter(string selectCommandText, SqlConnection connection)
    {
        SqlDataAdapter adapter = new SqlDataAdapter(selectCommandText, connection);
        adapter.SelectCommand.CommandTimeout = SqlCommandTimeoutSeconds();
        return adapter;
    }

    public static bool Config(string key, bool defaultValue)
    {
        string value = ConfigurationManager.AppSettings[key];
        if (string.IsNullOrEmpty(value) || value.Trim().Length == 0) return defaultValue;

        bool parsed;
        if (bool.TryParse(value, out parsed)) return parsed;

        return value == "1" || value.Equals("yes", StringComparison.OrdinalIgnoreCase)
            || value.Equals("on", StringComparison.OrdinalIgnoreCase);
    }

    public static string ToMD5(string str)
    {
        if (string.IsNullOrEmpty(str)) return "";
        
        using (MD5 md5 = MD5.Create())
        {
            byte[] inputBytes = Encoding.UTF8.GetBytes(str);
            byte[] hashBytes = md5.ComputeHash(inputBytes);

            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < hashBytes.Length; i++)
            {
                sb.Append(hashBytes[i].ToString("x2"));
            }
            return sb.ToString();
        }
    }
}
