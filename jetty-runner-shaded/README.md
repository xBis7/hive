## TLDR

This maven project has been created in order to generate a shaded version of the `org.eclipse.jetty:jetty-runner` jar.

Every Hive module that needs to use the shaded `org.eclipse.jetty:jetty-runner` jar, will be able to get it through a
dependency on `org.apache.hive:jetty-runner-shaded`.

We are making sure that `jetty-runner-shaded` is the first module to be built during a Hive build.

## Issue

Hadoop 3.3.6 uses jetty version `9.4.51.v20230217` while Hive uses jetty version `9.4.40.v20210413`.

When upgrading Hive's Hadoop dependency, we also have to upgrade the jetty version that Hive is using, in order to match Hadoop's jetty version.

Hadoop uses classes from this dependency

```xml
<dependency>
  <groupId>org.apache.directory.api</groupId>
  <artifactId>api-ldap-model</artifactId>
</dependency>
```

Hive doesn't have the `org.apache.directory.api:api-ldap-model` dependency but it has the `org.eclipse.jetty:jetty-runner` dependency which contains its own version of the entire `org.apache.directory.api` package. 

Same thing goes for `org.apache.mina` but we will focus on `org.apache.directory.api` for the rest of the README because the approach is the same.

Hadoop doesn't use the `jetty-runner` dependency and that's why it doesn't have the issues that appear in Hive after the upgrade.

The issue is that
* Hive calls Hadoop code
* The Hadoop code calls some classes from the `org.apache.directory.api` package
* Hadoop expects that these classes will be implemented by `api-ldap-model` dependency
* Hive doesn't have the dependency but it can find the classes from the `org.apache.directory.api` package that exists under the `jetty-runner` dependency and can be found on the classpath 
* When Hive calls the Hadoop code, we get this exception `java.lang.IncompatibleClassChangeError: Implementing class`

## Solution

A possible solution would be to use the `maven-shade-plugin` in order to rename the package `org.apache.directory.api` package under the `jetty-runner` dependency so that when Hive tries to access the classes, it will not find them under the `jetty-runner` jar. The `jetty-runner org.apache.directory.api` classes will need to be imported with their new package name, in order to be used.

The shaded jar with the renamed `org.apache.directory.api` package, will be the main artifact of this module.

In order to use the shaded jar, every dependency to the `jetty-runner`

```xml
<dependency>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-runner</artifactId>
  <version>${jetty.version}</version>
</dependency>
```

will have to be replaced by a dependency on this module

```xml
<dependency>
  <groupId>org.apache.hive</groupId>
  <artifactId>jetty-runner-shaded</artifactId>
  <version>${project.version}</version>
</dependency>
```

